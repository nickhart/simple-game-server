require "net/http"
require "uri"
require "json"
require "yaml"
require "optparse"

CONFIG = YAML.load_file(File.expand_path("config.yml", __dir__))

API_URL = CONFIG["api_url"]

options = {
  email: nil,
  password: nil
}

OptionParser.new do |opts|
  opts.banner = "Usage: create_player.rb --email EMAIL --password PASSWORD"

  opts.on("--email EMAIL", "User email") { |v| options[:email] = v }
  opts.on("--password PASSWORD", "User password") { |v| options[:password] = v }
end.parse!

raise "Email and password are required" unless options[:email] && options[:password]

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
  make_request(Net::HTTP::Post, path, body, headers.merge({ "Content-Type" => "application/json" }))
end

def login(email, password)
  response = make_request(
    Net::HTTP::Post,
    "/api/sessions",
    { email: email, password: password },
    { "Content-Type" => "application/json" }
  )

  if response.is_a?(Hash) && response.key?("access_token")
    response["access_token"]
  elsif response.is_a?(Hash) && response.dig("data", "access_token")
    response["data"]["access_token"]
  else
    raise "Login response did not contain an access_token"
  end
end

def register_user(email, password)
  begin
    make_request(
      Net::HTTP::Post,
      "/api/users",
      { user: { email: email, password: password } },
      { "Content-Type" => "application/json" }
    )
  rescue RuntimeError => e
    if e.message.include?("422") && e.message.include?("has already been taken")
      return
    else
      raise
    end
  end
end

def create_player(token, email)
  name = email.split("@").first
  make_request(
    Net::HTTP::Post,
    "/api/players",
    { player: { name: name } },
    {
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json"
    }
  )
end

puts "Creating player..."

register_user(options[:email], options[:password])
token = login(options[:email], options[:password])
create_player(token, options[:email])

puts "✅ Player created"