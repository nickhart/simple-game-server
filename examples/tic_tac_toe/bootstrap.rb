require "net/http"
require "uri"
require "json"
require "yaml"

CONFIG = YAML.load_file(File.expand_path("config.yml", __dir__))

# Ensure all required config keys are present and non-empty
required_keys = %w[api_url admin_email admin_password game_name state_json_schema]
missing = required_keys.select { |key| CONFIG[key].nil? || CONFIG[key].to_s.strip.empty? }
unless missing.empty?
  raise "Missing required config keys in config.yml: #{missing.join(', ')}"
end

API_URL = CONFIG["api_url"]
ADMIN_EMAIL = CONFIG["admin_email"]
ADMIN_PASSWORD = CONFIG["admin_password"]
GAME_NAME = CONFIG["game_name"]
STATE_JSON_SCHEMA = CONFIG["state_json_schema"]

def make_request(method_class, path, body = {}, headers = {})
  uri = URI("#{API_URL}#{path}")
  request = method_class.new(uri)
  headers.each { |k, v| request[k] = v }
  request.body = body.to_json unless body.empty?

  response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }

  parsed = JSON.parse(response.body) rescue nil
  unless response.is_a?(Net::HTTPSuccess)
    raise "#{method_class.name} #{path} failed: #{response.code} - #{response.body}"
  end

  parsed
end

def post(path, body = {}, headers = {})
  response = make_request(Net::HTTP::Post, path, body, headers.merge({ "Content-Type" => "application/json" }))
  response
end

def login(email, password)
  response = make_request(
    Net::HTTP::Post,
    "/api/sessions",
    { email: email, password: password },
    { "Content-Type" => "application/json" }
  )
  # If response is a Hash with "access_token", return it. If it's a "data" hash, unwrap it.
  if response.is_a?(Hash) && response.key?("access_token")
    response["access_token"]
  elsif response.is_a?(Hash) && response.key?("data") && response["data"].is_a?(Hash) && response["data"].key?("access_token")
    response["data"]["access_token"]
  else
    raise "Login response did not contain an access_token"
  end
end

def create_admin_user(email, password)
  uri = URI("#{API_URL}/api/admin/users")
  request = Net::HTTP::Post.new(uri)
  request["Content-Type"] = "application/json"
  request.body = {
    user: {
      email: email,
      password: password
    }
  }.to_json
  response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
  if response.code.to_i == 422 && response.body.include?("already exists")
    return
  end
  if response.code.to_i == 403 && response.body.include?("Admin user creation is not allowed")
    puts "⚠️ Admin user already exists, skipping creation"
    return
  end
  raise "Admin user creation failed: #{response.body}" unless response.is_a?(Net::HTTPSuccess)
end

def get_games(token)
  uri = URI("#{API_URL}/api/games")
  request = Net::HTTP::Get.new(uri)
  request["Authorization"] = "Bearer #{token}"
  request["Content-Type"] = "application/json"
  response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
  raise "Fetching games failed: #{response.code} - #{response.body}" unless response.is_a?(Net::HTTPSuccess)
  JSON.parse(response.body)
end

def update_game(token, game_id)
  uri = URI("#{API_URL}/api/games/#{game_id}")
  request = Net::HTTP::Patch.new(uri)
  request["Authorization"] = "Bearer #{token}"
  request["Content-Type"] = "application/json"
  request.body = {
    state_json_schema: STATE_JSON_SCHEMA
  }.to_json
  response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
  raise "Game update failed: #{response.body}" unless response.is_a?(Net::HTTPSuccess)
end

def create_game(token, name)
  games = get_games(token)
  existing = games.find { |g| g["name"] == name }
  if existing
    puts "⚠️ Game '#{name}' already exists. Updating schema..."
    update_game(token, existing["id"])
    return
  end

  uri = URI("#{API_URL}/api/games")
  request = Net::HTTP::Post.new(uri)
  request["Authorization"] = "Bearer #{token}"
  request["Content-Type"] = "application/json"
  request.body = {
    name: name,
    state_json_schema: STATE_JSON_SCHEMA
  }.to_json
  response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
  raise "Game creation failed: #{response.body}" unless response.is_a?(Net::HTTPSuccess)
end

puts "Bootstrapping admin user and game..."

create_admin_user(ADMIN_EMAIL, ADMIN_PASSWORD)
admin_token = login(ADMIN_EMAIL, ADMIN_PASSWORD)
create_game(admin_token, GAME_NAME)

puts "✅ Bootstrap complete"