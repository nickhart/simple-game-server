require "net/http"
require "json"
require "uri"
require_relative "config"
require_relative "game_session"
require_relative "result"

class GameClient
  attr_reader :token

  def initialize(server_url = "http://localhost:3000")
    @server_url = server_url
    @token = nil
  end

  def register(email, password)
    uri = URI("#{@server_url}/api/players")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["X-API-Key"] = Config::API_KEY
    request.body = {
      user: {
        email: email,
        password: password,
        password_confirmation: password
      }
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.code == "201"
      data = JSON.parse(response.body)
      @token = data["token"]
      puts "Successfully registered user #{data['user']['email']}"
      Result.success(data)
    else
      error_message = extract_error_message(response.body)
      puts "Failed to register: #{error_message}"
      Result.failure(error_message)
    end
  end

  def login(email, password)
    response = post("/api/sessions", { email: email, password: password })
    @token = response["token"]
  end

  def get_current_player
    response = get("/api/players/current")
    Player.new(response)
  end

  def create_game_session(player_id, min_players, max_players)
    response = post("/api/game_sessions/create/#{player_id}", {
      game_session: {
        min_players: min_players,
        max_players: max_players
      }
    })
    GameSession.new(response)
  end

  def join_game_session(player_id, game_session_id)
    response = post("/api/game_sessions/#{game_session_id}/join/#{player_id}")
    GameSession.new(response)
  end

  def list_game_sessions
    response = get("/api/game_sessions")
    response.map { |session| GameSession.new(session) }
  end

  def update_game_state(game_session_id, state)
    response = put("/api/game_sessions/#{game_session_id}", {
      game_session: {
        state: state
      }
    })
    GameSession.new(response)
  end

  def get_game_session(game_session_id)
    return Result.failure("No game session ID provided") unless game_session_id

    uri = URI("#{@server_url}/api/game_sessions/#{game_session_id}")
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{@token}"
    request["X-API-Key"] = Config::API_KEY

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.code == "200"
      data = JSON.parse(response.body)
      Result.success(GameSession.new(data))
    else
      error_message = extract_error_message(response.body)
      puts "Failed to get game session: #{error_message}"
      Result.failure(error_message)
    end
  end

  def start_game(game_session_id, player_id = nil)
    puts "Starting game with session_id: #{game_session_id}, player_id: #{player_id}"
    uri = URI("#{@server_url}/api/game_sessions/#{game_session_id}/start")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@token}"
    request["Content-Type"] = "application/json"
    request["X-API-Key"] = Config::API_KEY
    
    # Only include player_id in the request body if it's provided
    request_body = {}
    request_body[:player_id] = player_id if player_id
    
    request.body = request_body.to_json

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.code == "200"
      data = JSON.parse(response.body)
      game_session = GameSession.new(data)
      Result.success(game_session)
    else
      error_message = extract_error_message(response.body)
      puts "Failed to start game: #{error_message}"
      puts "Response body: #{response.body}"
      Result.failure(error_message)
    end
  end

  def leave_game(game_session_id, player_id)
    return Result.failure("No game session ID or player ID provided") unless game_session_id && player_id

    uri = URI("#{@server_url}/api/game_sessions/#{game_session_id}/leave?player_id=#{player_id}")
    request = Net::HTTP::Delete.new(uri)
    request["Authorization"] = "Bearer #{@token}"
    request["X-API-Key"] = Config::API_KEY

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.code == "200"
      puts "Left game session"
      Result.success(true)
    else
      error_message = extract_error_message(response.body)
      puts "Failed to leave game: #{error_message}"
      Result.failure(error_message)
    end
  end

  def make_move(game_session_id, player_id, position)
    return Result.failure("No game session ID or player ID provided") unless game_session_id && player_id

    # Get current game state
    game_session_result = get_game_session(game_session_id)
    return game_session_result if game_session_result.failure?

    # Update the game state on the server
    uri = URI("#{@server_url}/api/game_sessions/#{game_session_id}/update_game_state")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@token}"
    request["Content-Type"] = "application/json"
    request["X-API-Key"] = Config::API_KEY
    request.body = {
      player_id: player_id,
      state: {
        last_move: position
      }
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.code == "200"
      data = JSON.parse(response.body)
      Result.success(GameSession.new(data))
    else
      error_message = extract_error_message(response.body)
      puts "\nError (#{response.code}): #{error_message}\n"
      Result.failure(error_message)
    end
  end

  private

  def get(path)
    uri = URI("#{@server_url}#{path}")
    request = Net::HTTP::Get.new(uri)
    add_auth_header(request)
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    handle_response(response)
  end

  def post(path, body = {})
    uri = URI("#{@server_url}#{path}")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    add_auth_header(request)
    request.body = body.to_json
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    handle_response(response)
  end

  def put(path, body = {})
    uri = URI("#{@server_url}#{path}")
    request = Net::HTTP::Put.new(uri)
    request["Content-Type"] = "application/json"
    add_auth_header(request)
    request.body = body.to_json
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    handle_response(response)
  end

  def add_auth_header(request)
    request["Authorization"] = "Bearer #{@token}" if @token
  end

  def handle_response(response)
    case response
    when Net::HTTPSuccess
      JSON.parse(response.body)
    else
      raise "HTTP Error: #{response.code} - #{response.body}"
    end
  end

  def extract_error_message(response_body)
    begin
      data = JSON.parse(response_body)
      if data.is_a?(Hash) && data["error"]
        data["error"]
      elsif data.is_a?(Hash) && data["errors"]
        if data["errors"].is_a?(Array)
          data["errors"].join(", ")
        elsif data["errors"].is_a?(Hash)
          data["errors"].map { |k, v| "#{k}: #{v.join(", ")}" }.join(", ")
        else
          data["errors"].to_s
        end
      else
        response_body
      end
    rescue JSON::ParserError
      response_body
    end
  end
end
