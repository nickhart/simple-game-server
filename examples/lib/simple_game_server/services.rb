require_relative 'api_client'
require_relative 'clients/tokens_client'
require_relative 'clients/players_client'
require_relative 'clients/game_sessions_client'

module Services
  class << self
    attr_reader :api_client, :auth, :players, :sessions
  end

  # Bootstraps all shared clients with the given API URL and token
  #
  # @param api_url [String] the base URL for the game server
  # @param token   [String] the JWT access token
  def self.setup(api_url:, token:)
    @api_client = ApiClient.new(api_url).with_token(token)
    @tokens     = Clients::TokensClient.new(@api_client)
    @players    = Clients::PlayersClient.new(@api_client)
    @sessions   = Clients::GameSessionsClient.new(@api_client)
  end
end