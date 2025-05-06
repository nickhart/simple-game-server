require "yaml"
require "optparse"
require_relative "../lib/api_client"
require_relative "../lib/config_loader"
require_relative "../lib/clients/tokens_client"
require_relative "../lib/clients/users_client"
require_relative "../lib/clients/players_client"

CONFIG = ConfigLoader.load!(%w[api_url], config_dir: __dir__)
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

email = options[:email]
password = options[:password]

puts "Creating player..."

api = ApiClient.new(API_URL)

# Create user account (non-admin)
users = UsersClient.new(api)
create_result = users.create(email, password)

if create_result.failure?
  unless create_result.error.include?("already exists")
    raise "User creation failed: #{create_result.error}"
  end
  puts "⚠️ User already exists"
end

# Authenticate and get token
token_result = TokensClient.new(api).login(email, password)
raise "Login failed: #{token_result.error}" if token_result.failure?

token = token_result.data
puts "✅ Logged in"

# Create player profile
authed_api = api.with_token(token)
players = PlayersClient.new(authed_api)
name = email.split("@").first
create_player_result = players.create(name)

raise "Player creation failed: #{create_player_result.error}" if create_player_result.failure?
puts "✅ Player created"