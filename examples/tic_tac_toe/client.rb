require 'net/http'
require 'json'
require 'uri'
require_relative 'config'

class GameClient
  BASE_URL = 'http://localhost:3000/api'
  API_KEY = Config::API_KEY

  def initialize
    @token = nil
    @game_session_id = nil
    @player_id = nil
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
    request.body = {
      player: {
        name: "Player #{rand(1000)}"
      }
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.code == '201'
      data = JSON.parse(response.body)
      @player_id = data['id']
      @game_session_id = game_session_id
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

  def start_game
    return false unless @game_session_id

    uri = URI("#{BASE_URL}/game_sessions/#{@game_session_id}/start")
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@token}"
    request['X-API-Key'] = API_KEY

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.code == '200'
      puts "Game started!"
      true
    else
      error_message = extract_error_message(response.body)
      puts "Failed to start game: #{error_message}"
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