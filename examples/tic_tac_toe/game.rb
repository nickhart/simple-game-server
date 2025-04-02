require_relative "client"
require_relative "board"

class Game
  def initialize(email = nil, password = nil)
    @client = GameClient.new
    @board = Board.new
    @email = email
    @password = password
  end

  attr_reader :client

  def start
    unless login
      puts "Failed to login. Exiting..."
      return
    end

    loop do
      case show_menu
      when "1"
        create_new_game
      when "2"
        join_existing_game
      when "3"
        leave_current_game
      when "4"
        register_new_player
      when "5"
        break
      end
    end
  end

  def login
    if @email && @password
      @client.login(@email, @password)
    else
      print "Email: "
      email = STDIN.gets.chomp
      print "Password: "
      password = STDIN.gets.chomp
      @client.login(email, password)
    end
  end

  def make_move(position)
    return false unless position.between?(1, 9)
    return false if @board.get_position(position)

    # Make the move locally using the Board class's make_move method
    if @board.make_move(position, @current_player_index)
      puts "\nMaking move at position #{position} for player #{@current_player_index}"
      puts "Local board state before server update:"
      @board.display

      # Update the game state on the server
      if @client.make_move(@board.board)
        puts "Server update successful"
        true
      else
        puts "Server update failed"
        # If server update failed, revert the local move
        @board.make_move(position, 0)
        false
      end
    else
      false
    end
  end

  def create_game
    response = @client.create_game_session
    if response
      @game_session_id = response["id"]
      @board = Board.new
      puts "Game created! Waiting for opponent..."
      true
    else
      false
    end
  end

  def start_game
    return false unless @game_session_id && @player_id

    if @client.start_game(@game_session_id, @player_id)
      puts "Game started! It's your turn."
      true
    else
      puts "Failed to start game."
      false
    end
  end

  def play_game(session)
    players = session["players"]
    current_player = players.find { |p| p["id"] == @client.instance_variable_get(:@player_id) }
    opponent = players.find { |p| p["id"] != @client.instance_variable_get(:@player_id) }

    puts "\nGame started! You are playing against #{opponent['name']}"
    puts "You are: #{current_player['name']}"

    # Initialize current_player_index based on whether we're the first or second player
    @current_player_index = players.index(current_player)
    puts "Initial player index: #{@current_player_index}"

    # Always show the initial board state
    @board = Board.new
    @board.display

    loop do
      # Get latest state from server
      session = @client.get_game_session
      break unless session

      puts "\nReceived game session state:"
      puts "Current player index: #{session['current_player_index']}"
      puts "Board state: #{session['state']}"

      # Update the board with the server state if it exists
      if session["state"] && session["state"]["board"]
        @board = Board.new(session["state"]["board"])
        puts "Updated board with server state:"
        @board.display
      end

      # Check if it's our turn
      if session["current_player_index"] == players.index(current_player)
        print "Enter position (1-9): "
        position = STDIN.gets.chomp.to_i

        if make_move(position)
          if @board.winner
            puts "\n#{current_player['name']} wins!"
            break
          elsif @board.full?
            puts "\nIt's a tie!"
            break
          end
        else
          puts "Invalid move! Try again."
        end
      else
        print "\rWaiting for #{opponent['name']}'s turn... (Press Ctrl+C to cancel)"
        sleep 2
      end
    end
  end

  def create_new_game
    if @client.create_game_session
      @game_session_id = @client.game_session_id
      @player_id = @client.player_id
      puts "\nWaiting for another player to join..."
      wait_for_opponent
    else
      puts "Failed to create game. Please try again."
    end
  end

  def wait_for_opponent
    puts "\nWaiting for opponent to join..."
    loop do
      session = @client.get_game_session
      break unless session

      puts "Game session status: #{session['status']}"
      puts "Players: #{session['players'].size}/2"
      puts "Is creator: #{@client.is_creator}"
      puts "Game session ID: #{@client.game_session_id}"
      puts "Player ID: #{@client.player_id}"

      case session["status"]
      when "active"
        puts "\nGame is starting!"
        play_game(session)
        break
      when "waiting"
        if session["players"].size >= 2
          puts "\nBoth players have joined!"
          # Only the creator should start the game
          if @client.is_creator
            puts "Starting game..."
            if @client.start_game(@client.game_session_id, @client.player_id)
              play_game(session)
              break
            else
              puts "Failed to start game. Please try again."
              break
            end
          else
            puts "Waiting for game creator to start..."
            sleep 2
          end
        else
          print "\rWaiting for opponent... (#{session['players'].size}/2 players) (Press Ctrl+C to cancel)"
          sleep 5
        end
      else
        puts "\nUnexpected game status: #{session['status']}"
        break
      end
    end
  end

  private

  def show_menu
    puts "\n=== Tic Tac Toe ==="
    puts "1. Create new game"
    puts "2. Join existing game"
    puts "3. Leave current game"
    puts "4. Register new player"
    puts "5. Exit"
    print "\nChoice: "
    STDIN.gets.chomp
  end

  def join_existing_game
    sessions = @client.list_game_sessions
    waiting_sessions = sessions.select { |s| s["status"] == "waiting" }

    if waiting_sessions.empty?
      puts "No waiting games found."
      return
    end

    puts "\nAvailable games:"
    waiting_sessions.each do |session|
      puts "ID: #{session['id']} - Players: #{session['players'].size}/2"
    end

    print "\nEnter game ID to join: "
    game_id = STDIN.gets.chomp.to_i

    wait_for_opponent if @client.join_game_session(game_id)
  end

  def leave_current_game
    if @client.leave_game
      @board = Board.new
      puts "Left game successfully."
    end
  end

  def register_new_player
    print "Email: "
    email = STDIN.gets.chomp
    print "Password: "
    password = STDIN.gets.chomp
    print "Confirm Password: "
    confirm_password = STDIN.gets.chomp

    if password != confirm_password
      puts "Passwords don't match!"
      return
    end

    if @client.register(email, password)
      puts "Registration successful! You can now log in."
      login
    end
  end
end

# Parse command line arguments
if ARGV.any?
  i = 0
  game = nil

  while i < ARGV.length
    case ARGV[i]
    when "--help", "-h"
      puts <<~HELP
        Tic Tac Toe Game Client
        Usage: ruby game.rb [options] [arguments]

        Options:
          --help, -h           Show this help message
          --register           Register a new player
          --login             Login with existing credentials
          --create            Create a new game session
          --join <session_id> Join an existing game session
          --list              List available game sessions
          --leave             Leave current game session

        Examples:
          ruby game.rb --register email@example.com password
          ruby game.rb --login email@example.com password --create
          ruby game.rb --login email@example.com password --join 123
          ruby game.rb --list
          ruby game.rb --leave
      HELP
      exit 0
    when "--register"
      if i + 2 >= ARGV.length
        puts "Error: --register requires email and password arguments"
        puts "Usage: ruby game.rb --register email@example.com password"
        exit 1
      end
      email = ARGV[i + 1]
      password = ARGV[i + 2]
      game = Game.new
      if game.register_new_player(email, password)
        puts "Registration successful! You can now log in."
        game.login
      end
      i += 3
    when "--login"
      if i + 2 >= ARGV.length
        puts "Error: --login requires email and password arguments"
        puts "Usage: ruby game.rb --login email@example.com password"
        exit 1
      end
      email = ARGV[i + 1]
      password = ARGV[i + 2]
      game = Game.new(email, password)
      if game.login
        puts "Login successful!"
        i += 3
        # Check for additional commands after login
        if i < ARGV.length
          case ARGV[i]
          when "--create"
            game.create_new_game
            i += 1
          when "--join"
            sessions = game.client.list_game_sessions
            waiting_sessions = sessions.select { |s| s["status"] == "waiting" }

            if waiting_sessions.empty?
              puts "No waiting games found."
              exit 1
            end

            if i + 1 < ARGV.length && !ARGV[i + 1].start_with?("--")
              # Join specific game session
              game_id = ARGV[i + 1].to_i
              if game.client.join_game_session(game_id)
                game.wait_for_opponent
              else
                puts "Failed to join game session #{game_id}"
                exit 1
              end
              i += 2
            else
              # Join highest numbered game session
              highest_session = waiting_sessions.max_by { |s| s["id"] }
              if game.client.join_game_session(highest_session["id"])
                game.wait_for_opponent
              else
                puts "Failed to join game session #{highest_session['id']}"
                exit 1
              end
              i += 1
            end
          when "--list"
            sessions = game.client.list_game_sessions
            waiting_sessions = sessions.select { |s| s["status"] == "waiting" }

            if waiting_sessions.empty?
              puts "No waiting games found."
              exit 0
            end

            puts "\nAvailable games:"
            waiting_sessions.each do |session|
              puts "ID: #{session['id']} - Players: #{session['players'].size}/2"
            end
            i += 1
          when "--leave"
            game.leave_current_game
            i += 1
          else
            puts "Error: Unknown command '#{ARGV[i]}'"
            puts "Run 'ruby game.rb --help' for usage information"
            exit 1
          end
        else
          # No additional commands, start interactive mode
          game.start
        end
      else
        puts "Login failed. Please check your credentials."
        exit 1
      end
    when "--create"
      if !game || !game.client.instance_variable_get(:@token)
        puts "Please login first."
        exit 1
      end
      game.create_new_game
      i += 1
    when "--join"
      if !game || !game.client.instance_variable_get(:@token)
        puts "Please login first."
        exit 1
      end
      sessions = game.client.list_game_sessions
      waiting_sessions = sessions.select { |s| s["status"] == "waiting" }

      if waiting_sessions.empty?
        puts "No waiting games found."
        exit 1
      end

      if i + 1 < ARGV.length && !ARGV[i + 1].start_with?("--")
        # Join specific game session
        game_id = ARGV[i + 1].to_i
        if game.client.join_game_session(game_id)
          game.wait_for_opponent
        else
          puts "Failed to join game session #{game_id}"
          exit 1
        end
        i += 2
      else
        # Join highest numbered game session
        highest_session = waiting_sessions.max_by { |s| s["id"] }
        if game.client.join_game_session(highest_session["id"])
          game.wait_for_opponent
        else
          puts "Failed to join game session #{highest_session['id']}"
          exit 1
        end
        i += 1
      end
    when "--list"
      if !game || !game.client.instance_variable_get(:@token)
        puts "Please login first."
        exit 1
      end
      sessions = game.client.list_game_sessions
      waiting_sessions = sessions.select { |s| s["status"] == "waiting" }

      if waiting_sessions.empty?
        puts "No waiting games found."
        exit 0
      end

      puts "\nAvailable games:"
      waiting_sessions.each do |session|
        puts "ID: #{session['id']} - Players: #{session['players'].size}/2"
      end
      i += 1
    when "--leave"
      if !game || !game.client.instance_variable_get(:@token)
        puts "Please login first."
        exit 1
      end
      game.leave_current_game
      i += 1
    else
      puts "Error: Unknown command '#{ARGV[i]}'"
      puts "Run 'ruby game.rb --help' for usage information"
      exit 1
    end
  end
  exit 0
end

# Start the game if no arguments provided
begin
  Game.new.start
rescue Interrupt
  puts "\nGame interrupted. Goodbye!"
end
