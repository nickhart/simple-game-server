require "net/http"
require "json"
require "uri"
require_relative "config"
require_relative "game_session"
require_relative "result"

class GameClient
  BASE_URL = "http://localhost:3000/api".freeze
  API_KEY = Config::API_KEY

  def initialize
    @token = nil
  end

  def register(email, password)
    uri = URI("#{BASE_URL}/players")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["X-API-Key"] = API_KEY
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
    uri = URI("#{BASE_URL}/login")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["X-API-Key"] = API_KEY
    request.body = { email: email, password: password }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.code == "200"
      data = JSON.parse(response.body)
      @token = data["token"]
      Result.success(data)
    else
      error_message = extract_error_message(response.body)
      puts "Login failed: #{error_message}"
      Result.failure(error_message)
    end
  end

  def create_game_session
    uri = URI("#{BASE_URL}/game_sessions")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@token}"
    request["Content-Type"] = "application/json"
    request["X-API-Key"] = API_KEY
    request.body = {
      game_session: {
        status: "waiting",
        min_players: 2,
        max_players: 2,
        state: { board: Board.new.board }
      }
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.code == "201"
      data = JSON.parse(response.body)
      # Ensure the creator_id is set to the current user's ID
      # This is needed for the GameSession to correctly assign the player_id
      data['creator_id'] = data['players'].first['user_id'] if data['players'] && data['players'].any?
      game_session = GameSession.new(data)
      puts "Created game session: #{game_session.id}"
      Result.success(game_session)
    else
      error_message = extract_error_message(response.body)
      puts "Failed to create game session: #{error_message}"
      Result.failure(error_message)
    end
  end

  def join_game_session(game_session_id)
    result = get_game_session(game_session_id)
    return result unless result.success?
    game_session = result.data
    puts "current players (before join): #{game_session.players}"
    puts "current player (before join): #{game_session.current_player_index}"
    puts "creator (before join): #{game_session.creator_id}"

    uri = URI("#{BASE_URL}/game_sessions/#{game_session_id}/join")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@token}"
    request["Content-Type"] = "application/json"
    request["X-API-Key"] = API_KEY

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    
    # Get the updated game session after joining
    result = get_game_session(game_session_id)
    return result unless result.success?
    game_session = result.data
    puts "current players (after join): #{game_session.players}"
    puts "current player (after join): #{game_session.current_player_index}"
    puts "creator (after join): #{game_session.creator_id}"

    if response.code == "200"
      puts "Joined game session as player: #{game_session.player_id}"
      Result.success(game_session)
    else
      error_message = extract_error_message(response.body)
      puts "Failed to join game session: #{error_message}"
      Result.failure(error_message)
    end
  end

  def get_game_session(game_session_id)
    return Result.failure("No game session ID provided") unless game_session_id

    uri = URI("#{BASE_URL}/game_sessions/#{game_session_id}")
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{@token}"
    request["X-API-Key"] = API_KEY

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
    uri = URI("#{BASE_URL}/game_sessions/#{game_session_id}/start")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@token}"
    request["Content-Type"] = "application/json"
    request["X-API-Key"] = API_KEY
    
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

    uri = URI("#{BASE_URL}/game_sessions/#{game_session_id}/leave?player_id=#{player_id}")
    request = Net::HTTP::Delete.new(uri)
    request["Authorization"] = "Bearer #{@token}"
    request["X-API-Key"] = API_KEY

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

  def list_game_sessions
    uri = URI("#{BASE_URL}/game_sessions")
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{@token}"
    request["X-API-Key"] = API_KEY

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.code == "200"
      data = JSON.parse(response.body)
      Result.success(data)
    else
      error_message = extract_error_message(response.body)
      puts "Failed to list game sessions: #{error_message}"
      Result.failure(error_message)
    end
  end

  def make_move(game_session_id, player_id, position)
    return Result.failure("No game session ID or player ID provided") unless game_session_id && player_id

    # Get current game state
    game_session_result = get_game_session(game_session_id)
    return game_session_result if game_session_result.failure?

    # Update the game state on the server
    uri = URI("#{BASE_URL}/game_sessions/#{game_session_id}/update_game_state")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@token}"
    request["Content-Type"] = "application/json"
    request["X-API-Key"] = API_KEY
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

  attr_reader :token

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
