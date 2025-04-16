require "net/http"
require "json"
require "uri"
require_relative "config"
require_relative "game_session"
require_relative "result"

class HttpClient
  def initialize(server_url, token = nil)
    @server_url = server_url
    @token = token
  end

  def get(path)
    uri = URI("#{@server_url}#{path}")
    request = Net::HTTP::Get.new(uri)
    request["Content-Type"] = "application/json"
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

  def delete(path)
    uri = URI("#{@server_url}#{path}")
    request = Net::HTTP::Delete.new(uri)
    request["Content-Type"] = "application/json"
    add_auth_header(request)
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    handle_response(response)
  end

  private

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
end

class GameClient
  attr_reader :token

  def initialize(server_url = "http://localhost:3000")
    @http = HttpClient.new(server_url)
    @token = nil
  end

  def register(email, password)
    response = @http.post("/api/players", {
                            user: {
                              email: email,
                              password: password,
                              password_confirmation: password
                            }
                          })

    if response["token"]
      @token = response["token"]
      @http = HttpClient.new(@http.instance_variable_get(:@server_url), @token)
      puts "Successfully registered user #{response['user']['email']}"
      Result.success(response)
    else
      error_message = extract_error_message(response.to_json)
      puts "Failed to register: #{error_message}"
      Result.failure(error_message)
    end
  end

  def login(email, password)
    response = @http.post("/api/sessions", { email: email, password: password })
    @token = response["token"]
    @http = HttpClient.new(@http.instance_variable_get(:@server_url), @token)
  end

  def current_player
    response = @http.get("/api/players/current")
    Player.new(response)
  end

  def create_game_session(player_id, game_name = "Tic-Tac-Toe")
    response = @http.post("/api/game_sessions/create/#{player_id}", {
                            game_session: {
                              game_name: game_name
                            }
                          })
    GameSession.new(response)
  end

  def join_game_session(player_id, game_session_id)
    response = @http.post("/api/game_sessions/#{game_session_id}/join/#{player_id}")
    GameSession.new(response)
  end

  def list_game_sessions
    response = @http.get("/api/game_sessions")
    response.map { |session| GameSession.new(session) }
  end

  def update_game_state(game_session_id, state, status = :active, winner = nil)
    state["winner"] = winner if winner
    response = @http.put("/api/game_sessions/#{game_session_id}", {
                           game_session: {
                             state: state,
                             status: status
                           }
                         })
    Result.success(GameSession.new(response))
  rescue StandardError => e
    puts "Error updating game state: #{e.message}"
    Result.failure(e.message)
  end

  def get_game_session(game_session_id)
    return Result.failure("No game session ID provided") unless game_session_id

    begin
      response = @http.get("/api/game_sessions/#{game_session_id}")
      Result.success(GameSession.new(response))
    rescue StandardError => e
      puts "Error getting game session: #{e.message}"
      Result.failure(e.message)
    end
  end

  def start_game(game_session_id, player_id = nil)
    puts "Starting game with session_id: #{game_session_id}, player_id: #{player_id}"
    request_body = {}
    request_body[:player_id] = player_id if player_id

    response = @http.post("/api/game_sessions/#{game_session_id}/start", request_body)
    Result.success(GameSession.new(response))
  rescue StandardError => e
    puts "Failed to start game: #{e.message}"
    Result.failure(e.message)
  end

  def leave_game(game_session_id, player_id)
    return Result.failure("No game session ID or player ID provided") unless game_session_id && player_id

    @http.delete("/api/game_sessions/#{game_session_id}/leave?player_id=#{player_id}")
    puts "Left game session"
    Result.success(true)
  rescue StandardError => e
    puts "Failed to leave game: #{e.message}"
    Result.failure(e.message)
  end

  # def make_move(game_session_id, player_id, position)
  #   return Result.failure("No game session ID or player ID provided") unless game_session_id && player_id

  #   game_session_result = get_game_session(game_session_id)
  #   return game_session_result if game_session_result.failure?

  #   response = @http.post("/api/game_sessions/#{game_session_id}/update_game_state", {
  #     player_id: player_id,
  #     state: {
  #       last_move: position
  #     }
  #   })
  #   Result.success(GameSession.new(response))
  # rescue StandardError => e
  #   puts "\nError: #{e.message}\n"
  #   Result.failure(e.message)
  # end

  private

  def extract_error_message(response_body)
    data = JSON.parse(response_body)
    return data["error"] if data.is_a?(Hash) && data["error"]
    return handle_errors(data["errors"]) if data.is_a?(Hash) && data["errors"]

    response_body
  rescue JSON::ParserError
    response_body
  end

  def handle_errors(errors)
    return errors.join(", ") if errors.is_a?(Array)
    return format_hash_errors(errors) if errors.is_a?(Hash)

    errors.to_s
  end

  def format_hash_errors(errors)
    errors.map { |k, v| "#{k}: #{v.join(', ')}" }.join(", ")
  end
end
