require "yaml"
require_relative "../lib/api_client"
require_relative "../lib/result"
require_relative "../lib/clients/tokens_client"
require_relative "../lib/clients/admin_users_client"
require_relative "../lib/clients/games_client"
require_relative "../lib/clients/admin_games_client"
require_relative "../lib/config_loader"

CONFIG = ConfigLoader.load!(%w[
  api_url
  admin_email
  admin_password
  game_name
  state_json_schema
], config_dir: __dir__)

api_url = CONFIG["api_url"]
email = CONFIG["admin_email"]
password = CONFIG["admin_password"]
game_name = CONFIG["game_name"]
schema = CONFIG["state_json_schema"]

puts "Bootstrapping admin user and game..."

api = ApiClient.new(api_url)

# Ensure admin user exists
admin_users = AdminUsersClient.new(api)
create_result = admin_users.create(email, password)

if create_result.failure?
  unless create_result.error.include?("already exists") || create_result.error.include?("not allowed")
    raise "Admin user creation failed: #{create_result.error}"
  end
  puts "⚠️ Admin user already exists or creation not allowed"
end

# Log in as admin
token_result = TokensClient.new(api).login(email, password)
raise "Login failed: #{token_result.error}" if token_result.failure?

token = token_result.data
authed_api = api.with_token(token)

# Create or update game
games_client = GamesClient.new(authed_api)
list_result = games_client.list

raise "Failed to list games: #{list_result.error}" if list_result.failure?

existing = list_result.data.find { |g| g["name"] == game_name }
if existing
  puts "⚠️ Game '#{game_name}' already exists. Updating schema..."
  admin_games = AdminGamesClient.new(authed_api)
  update_result = admin_games.update(existing["id"], schema)
  raise "Failed to update game: #{update_result.error}" if update_result.failure?
else
  admin_games = AdminGamesClient.new(authed_api)
  create_result = admin_games.create(game_name, schema)
  raise "Failed to create game: #{create_result.error}" if create_result.failure?
end

puts "✅ Bootstrap complete"
