require_relative "client"
require_relative "board"

class Game
  WINNING_COMBINATIONS = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], # Rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], # Columns
    [0, 4, 8], [2, 4, 6] # Diagonals
  ].freeze

  attr_reader :client, :board, :game_session_id
  
  def initialize(client = nil)
    @client = client || GameClient.new
    @board = Board.new
    @game_session_id = nil
  end

  def start
    puts "\nWelcome to Tic Tac Toe!"
    puts "1. Register new player"
    puts "2. Login"
    puts "3. Create new game"
    puts "4. Join existing game"
    puts "5. List available games"
    puts "6. Leave current game"
    puts "7. Exit"
    puts "\nEnter your choice (1-7):"

    choice = $stdin.gets.chomp
    handle_choice(choice)
  end

  def make_move(position)
    return false unless @board.valid_move?(position)
    return false unless @client.make_move(@board.board)

    @board.make_move(position, @client.current_player_index)
    true
  end

  def create_new_game
    return false unless @client.create_game_session
    wait_for_opponent
    true
  end

  def play_game(session)
    players = session["players"]
    current_player = players.find { |p| p["id"] == @client.instance_variable_get(:@player_id) }
    opponent = players.find { |p| p["id"] != @client.instance_variable_get(:@player_id) }

    puts "\nGame started!"
    puts "You are playing as: #{current_player['name']}"
    puts "Your opponent is: #{opponent['name']}"
    puts "You are #{players.index(current_player) == 0 ? 'X' : 'O'}"

    game_loop(session, players, current_player)
  end

  def wait_for_opponent
    puts "\nWaiting for opponent to join..."
    puts "Press Ctrl+C to cancel"

    loop do
      session = @client.get_game_session
      break unless session

      case session["status"]
      when "active"
        puts "\nOpponent joined! Starting game..."
        play_game(session)
        break
      when "waiting"
        if session["players"].size >= 2 && @client.start_game(@client.game_session_id, @client.player_id)
          puts "\nGame started!"
          play_game(session)
          break
        end
        sleep 2
      end
    end
  rescue Interrupt
    puts "\nWaiting cancelled."
  end

  def join_existing_game
    sessions = @client.list_game_sessions
    return false unless sessions

    waiting_sessions = sessions.select { |s| s["status"] == "waiting" }
    if waiting_sessions.empty?
      puts "No waiting games found."
      return false
    end

    puts "\nAvailable games:"
    waiting_sessions.each do |s|
      creator = s["creator"]
      puts "Game #{s['id']} - Created by: #{creator['name']}"
    end

    puts "\nEnter game ID to join:"
    game_id = $stdin.gets.chomp.to_i

    @client.join_game_session(game_id)
  end

  def register_new_player(email = nil, password = nil)
    if email && password
      @client.register(email, password)
    else
      puts "\nEnter email:"
      email = $stdin.gets.chomp

      puts "Enter password:"
      password = $stdin.gets.chomp

      puts "Confirm password:"
      confirm_password = $stdin.gets.chomp

      if password != confirm_password
        puts "Passwords do not match!"
        return false
      end

      @client.register(email, password)
    end
  end

  def login(email = nil, password = nil)
    if email && password
      @client.login(email, password)
    else
      puts "\nEnter email:"
      email = $stdin.gets.chomp

      puts "Enter password:"
      password = $stdin.gets.chomp

      @client.login(email, password)
    end
  end

  private

  def handle_choice(choice)
    case choice
    when "1"
      register_new_player
    when "2"
      login
    when "3"
      create_new_game
    when "4"
      join_existing_game
    when "5"
      list_available_games
    when "6"
      leave_game
    when "7"
      exit
    else
      puts "Invalid choice. Please try again."
    end
  end

  def game_loop(session, players, current_player)
    loop do
      @board.display

      if session["current_player_index"] == players.index(current_player)
        puts "\nYour turn! Enter position (1-9):"
        position = $stdin.gets.chomp.to_i
        make_move(position)
      else
        puts "\nWaiting for opponent's move..."
        sleep 2
      end

      session = @client.get_game_session
      break unless session

      @board = Board.new(session["state"]["board"]) if session["state"] && session["state"]["board"]

      if @board.winner
        @board.display
        winner = players[session["current_player_index"]]
        puts "\nGame Over! #{winner['name']} wins!"
        break
      end

      next unless @board.full?

      @board.display
      puts "\nGame Over! It's a tie!"
      break
    end
  end

  def list_available_games
    sessions = @client.list_game_sessions
    return unless sessions

    waiting_sessions = sessions.select { |s| s["status"] == "waiting" }
    if waiting_sessions.empty?
      puts "No waiting games found."
      return
    end

    puts "\nAvailable games:"
    waiting_sessions.each do |s|
      creator = s["creator"]
      puts "Game #{s['id']} - Created by: #{creator['name']}"
    end
  end

  def leave_game
    return unless @client.leave_game

    puts "Left the game successfully."
  end
end

# Command line interface
if __FILE__ == $PROGRAM_NAME
  game = nil
  i = 0

  while i < ARGV.length
    case ARGV[i]
    when "--help", "-h"
      puts "Usage: ruby game.rb [options]"
      puts "Options:"
      puts "  --register <email> <password>  Register a new player"
      puts "  --login <email> <password>     Login with existing credentials"
      puts "  --create                       Create a new game"
      puts "  --join [game_id]               Join an existing game (or latest waiting game)"
      puts "  --list                         List available games"
      puts "  --leave                        Leave current game"
      exit
    when "--register"
      if i + 2 >= ARGV.length
        puts "Error: Email and password required for registration"
        exit 1
      end

      email = ARGV[i + 1]
      password = ARGV[i + 2]
      game = Game.new
      if game.register_new_player(email, password)
        puts "Registration successful!"
      else
        puts "Registration failed."
        exit 1
      end
      i += 2
    when "--login"
      if i + 2 >= ARGV.length
        puts "Error: Email and password required for login"
        exit 1
      end

      email = ARGV[i + 1]
      password = ARGV[i + 2]
      game = Game.new
      if game.login(email, password)
        puts "Login successful!"
      else
        puts "Login failed."
        exit 1
      end
      i += 2
    when "--create"
      if !game || !game.client.instance_variable_get(:@token)
        puts "Error: Must login first"
        exit 1
      end

      if game.create_new_game
        puts "Game created successfully! Waiting for opponent..."
        game.wait_for_opponent
      else
        puts "Failed to create game."
        exit 1
      end
    when "--join"
      if !game || !game.client.instance_variable_get(:@token)
        puts "Error: Must login first"
        exit 1
      end

      sessions = game.client.list_game_sessions
      waiting_sessions = sessions.select { |s| s["status"] == "waiting" }
      if waiting_sessions.empty?
        puts "No waiting games found."
        exit 1
      end

      if i + 1 < ARGV.length && !ARGV[i + 1].start_with?("--")
        game_id = ARGV[i + 1].to_i
        if game.client.join_game_session(game_id)
          puts "Joined game successfully! Waiting for opponent..."
          game.wait_for_opponent
        else
          puts "Failed to join game."
          exit 1
        end
        i += 1
      else
        highest_session = waiting_sessions.max_by { |s| s["id"] }
        if game.client.join_game_session(highest_session["id"])
          puts "Joined latest game successfully! Waiting for opponent..."
          game.wait_for_opponent
        else
          puts "Failed to join game."
          exit 1
        end
      end
    when "--list"
      if !game || !game.client.instance_variable_get(:@token)
        puts "Error: Must login first"
        exit 1
      end

      sessions = game.client.list_game_sessions
      waiting_sessions = sessions.select { |s| s["status"] == "waiting" }
      if waiting_sessions.empty?
        puts "No waiting games found."
        exit
      end

      puts "\nAvailable games:"
      waiting_sessions.each do |s|
        creator = s["creator"]
        puts "Game #{s['id']} - Created by: #{creator['name']}"
      end
    when "--leave"
      if !game || !game.client.instance_variable_get(:@token)
        puts "Error: Must login first"
        exit 1
      end

      if game.client.leave_game
        puts "Left the game successfully."
      else
        puts "Failed to leave game."
        exit 1
      end
    end
    i += 1
  end

  game.start unless ARGV.any?
end
