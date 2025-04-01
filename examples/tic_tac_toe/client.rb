require 'net/http'
require 'json'
require 'uri'
require_relative 'config'

class GameClient
  BASE_URL = 'http://localhost:3000/api'
  API_KEY = Config::API_KEY

  attr_reader :is_creator, :game_session_id, :player_id

  def initialize
    @token = nil
    @game_session_id = nil
    @player_id = nil
    @is_creator = false
  end

  def register(email, password)
    uri = URI("#{BASE_URL}/players")
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['X-API-Key'] = API_KEY
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

    if response.code == '201'
      data = JSON.parse(response.body)
      @token = data['token']
      puts "Successfully registered user #{data['user']['email']}"
      true
    else
      error_message = extract_error_message(response.body)
      puts "Failed to register: #{error_message}"
      false
    end
  end

  def login(email, password)
    uri = URI("#{BASE_URL}/login")
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['X-API-Key'] = API_KEY
    request.body = { email: email, password: password }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    
    if response.code == '200'
      data = JSON.parse(response.body)
      @token = data['token']
      true
    else
      error_message = extract_error_message(response.body)
      puts "Login failed: #{error_message}"
      false
    end
  end

  def create_game_session
    uri = URI("#{BASE_URL}/game_sessions")
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@token}"
    request['Content-Type'] = 'application/json'
    request['X-API-Key'] = API_KEY
    request.body = {
      game_session: {
        status: 'waiting',
        min_players: 2,
        max_players: 2
      }
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.code == '201'
      data = JSON.parse(response.body)
      @game_session_id = data['id']
      @is_creator = true
      puts "Created game session: #{@game_session_id}"
      
      # Automatically join the game we just created
      join_game_session(@game_session_id)
    else
      error_message = extract_error_message(response.body)
      puts "Failed to create game session: #{error_message}"
      false
    end
  end

  def join_game_session(game_session_id)
    uri = URI("#{BASE_URL}/game_sessions/#{game_session_id}/join")
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@token}"
    request['Content-Type'] = 'application/json'
    request['X-API-Key'] = API_KEY

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.code == '200'
      data = JSON.parse(response.body)
      @game_session_id = game_session_id
      @player_id = data['players'].last['id']  # Get the ID of the player we just created
      # Only set is_creator to false if we didn't just create this game
      @is_creator = false unless @is_creator
      puts "Joined game session as player: #{@player_id}"
      true
    else
      error_message = extract_error_message(response.body)
      puts "Failed to join game session: #{error_message}"
      false
    end
  end

  def get_game_session
    return nil unless @game_session_id

    uri = URI("#{BASE_URL}/game_sessions/#{@game_session_id}")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@token}"
    request['X-API-Key'] = API_KEY

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.code == '200'
      JSON.parse(response.body)
    else
      error_message = extract_error_message(response.body)
      puts "Failed to get game session: #{error_message}"
      nil
    end
  end

  def start_game(game_session_id, player_id)
    puts "Starting game with session_id: #{game_session_id}, player_id: #{player_id}"
    uri = URI("#{BASE_URL}/game_sessions/#{game_session_id}/start")
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@token}"
    request['Content-Type'] = 'application/json'
    request['X-API-Key'] = API_KEY
    request.body = {
      player_id: player_id
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.code == '200'
      data = JSON.parse(response.body)
      @current_player_index = data['current_player_index']
      true
    else
      error_message = extract_error_message(response.body)
      puts "Failed to start game: #{error_message}"
      puts "Response body: #{response.body}"
      false
    end
  end

  def leave_game
    return false unless @game_session_id && @player_id

    uri = URI("#{BASE_URL}/game_sessions/#{@game_session_id}/leave?player_id=#{@player_id}")
    request = Net::HTTP::Delete.new(uri)
    request['Authorization'] = "Bearer #{@token}"
    request['X-API-Key'] = API_KEY

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.code == '200'
      puts "Left game session"
      @game_session_id = nil
      @player_id = nil
      @is_creator = false
      true
    else
      error_message = extract_error_message(response.body)
      puts "Failed to leave game: #{error_message}"
      false
    end
  end

  def list_game_sessions
    uri = URI("#{BASE_URL}/game_sessions")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@token}"
    request['X-API-Key'] = API_KEY

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.code == '200'
      JSON.parse(response.body)
    else
      error_message = extract_error_message(response.body)
      puts "Failed to list game sessions: #{error_message}"
      []
    end
  end

  def make_move(board_state)
    return false unless @game_session_id && @player_id

    # Update the game state on the server
    uri = URI("#{BASE_URL}/game_sessions/#{@game_session_id}/update_game_state")
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@token}"
    request['Content-Type'] = 'application/json'
    request['X-API-Key'] = API_KEY
    request.body = {
      player_id: @player_id,
      state: {
        board: board_state,
        current_player_index: @current_player_index,
        last_move: nil
      }
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.code == '200'
      true
    else
      error_message = extract_error_message(response.body)
      puts "\nError (#{response.code}): #{error_message}\n"
      false
    end
  end

  private

  def extract_error_message(response_body)
    begin
      data = JSON.parse(response_body)
      if data.is_a?(Hash)
        data['error'] || data['message'] || response_body
      else
        response_body
      end
    rescue JSON::ParserError
      # If the response is HTML or not JSON, return a generic error
      "Server error occurred"
    end
  end
end 