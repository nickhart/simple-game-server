require_relative "client"
require_relative "board"
require_relative "result"

class Game

  attr_reader :client, :game_session
  
  def initialize(client = nil)
    @client = client || GameClient.new
    @game_session = nil
  end

  def display_menu
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

  def make_move(game_session_id, player_id, position)
    # Let the Board class handle the validation
    result = @client.make_move(game_session_id, player_id, position)
    return false unless result.success?
    
    game_session = result.data
    true
  end

  def create_new_game
    result = @client.create_game_session
    return false unless result.success?
    
    game_session = result.data
    puts "Created game session: #{game_session.id}"
    wait_for_opponent(game_session.id, game_session.player_id)
    true
  end

  def play_game(game_session)
    players = game_session.players
    current_player = players.find { |p| p.id == game_session.player_id }
    opponent = players.find { |p| p.id != game_session.player_id }

    puts "\nGame started!"
    puts "You are playing as: #{current_player.name}"
    puts "Your opponent is: #{opponent.name}"
    puts "You are #{players.index(current_player) == 0 ? 'X' : 'O'}"

    game_loop(game_session, players, current_player)
  end

  def wait_for_opponent(game_session_id, player_id)
    puts "\nWaiting for opponent to join..."
    puts "Press Ctrl+C to cancel"

    loop do
      result = @client.get_game_session(game_session_id)
      break unless result.success?

      game_session = result.data
      case game_session.status
      when "active"
        puts "\nOpponent joined! Starting game..."
        play_game(game_session)
        break
      when "waiting"
        if game_session.players.size >= 2
          # Start the game without specifying a player_id
          start_result = @client.start_game(game_session_id)
          if start_result.success?
            puts "\nGame started!"
            play_game(start_result.data)
            break
          end
        end
        sleep 2
      end
    end
  rescue Interrupt
    puts "\nWaiting cancelled."
  end

  def join_existing_game
    result = @client.list_game_sessions
    return false unless result.success?

    sessions = result.data
    waiting_sessions = sessions.select { |s| s["status"] == "waiting" }
    if waiting_sessions.empty?
      puts "No waiting games found."
      return false
    end

    puts "\nAvailable games:"
    waiting_sessions.each do |s|
      session = GameSession.new(s)
      puts "Game #{session.id} - Created by: #{session.creator_id}"
    end

    puts "\nEnter game ID to join (or 'b' to go back):"
    game_id = $stdin.gets.chomp
    return false if game_id.downcase == 'b'

    join_result = @client.join_game_session(game_id)
    return false unless join_result.success?

    game_session = join_result.data
    puts "Joined game session: #{game_session.id}"
    
    if game_session.active?
      play_game(game_session)
    else
      wait_for_opponent(game_session.id, game_session.player_id)
    end
    
    true
  end

  def register_new_player(email = nil, password = nil)
    if email && password
      result = @client.register(email, password)
      return result.success?
    end

    puts "\nRegister new player"
    print "Email: "
    email = $stdin.gets.chomp
    print "Password: "
    password = $stdin.gets.chomp

    result = @client.register(email, password)
    if result.success?
      puts "Registration successful!"
      true
    else
      puts "Registration failed: #{result.error}"
      false
    end
  end

  def login(email = nil, password = nil)
    if email && password
      result = @client.login(email, password)
      return result.success?
    end

    puts "\nLogin"
    print "Email: "
    email = $stdin.gets.chomp
    print "Password: "
    password = $stdin.gets.chomp

    result = @client.login(email, password)
    if result.success?
      puts "Login successful!"
      true
    else
      puts "Login failed: #{result.error}"
      false
    end
  end

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
      puts "Goodbye!"
      exit
    else
      puts "Invalid choice. Please try again."
    end

    display_menu
  end

  def game_loop(game_session, players, current_player)
    @game_session = game_session
    @board = Board.new(game_session.board)
    
    loop do
      @board.display
      
      if game_session.my_turn?
        puts "\nYour turn! Enter position (0-8):"
        position = $stdin.gets.chomp.to_i
        
        if make_move(game_session.id, game_session.player_id, position)
          # Board is updated in make_move
        else
          puts "Invalid move. Try again."
          next
        end
      else
        puts "\nWaiting for opponent's move..."
        sleep 2
        
        # Get updated game state
        result = @client.get_game_session(game_session.id)
        next unless result.success?
        
        game_session = result.data
        
        if game_session.finished?
          @game_session.board.display
          puts "\nGame over!"
          break
        end
      end
      
      if @board.winner || @board.full?
        @game_session.board.display
        puts "\nGame over!"
        break
      end
    end
  end

  def list_available_games
    result = @client.list_game_sessions
    return false unless result.success?

    sessions = result.data
    waiting_sessions = sessions.select { |s| s["status"] == "waiting" }
    
    if waiting_sessions.empty?
      puts "No waiting games found."
      return false
    end

    puts "\nAvailable games:"
    waiting_sessions.each do |s|
      session = GameSession.new(s)
      puts "Game #{session.id} - Created by: #{session.creator_id}"
    end
    
    true
  end

  def leave_game
    # This method would need game_session_id and player_id parameters
    # For simplicity, we'll just return true for now
    puts "Left the game."
    true
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

      result = game.client.list_game_sessions
      unless result.success?
        puts "Error: Failed to list game sessions: #{result.error}"
        exit 1
      end
      
      sessions = result.data
      waiting_sessions = sessions.select { |s| s["status"] == "waiting" }
      if waiting_sessions.empty?
        puts "No waiting games found."
        exit 1
      end

      if i + 1 < ARGV.length && !ARGV[i + 1].start_with?("--")
        game_id = ARGV[i + 1].to_i
        join_result = game.client.join_game_session(game_id)
        unless join_result.success?
          puts "Error: Failed to join game: #{join_result.error}"
          exit 1
        end
        
        game_session = join_result.data
        puts "Joined game session: #{game_session.id}"
        
        if game_session.active?
          game.play_game(game_session)
        else
          game.wait_for_opponent(game_session.id, game_session.player_id)
        end
      else
        # Join the first waiting game
        game_id = waiting_sessions.first["id"]
        join_result = game.client.join_game_session(game_id)
        unless join_result.success?
          puts "Error: Failed to join game: #{join_result.error}"
          exit 1
        end
        
        game_session = join_result.data
        puts "Joined game session: #{game_session.id}"
        
        if game_session.active?
          game.play_game(game_session)
        else
          game.wait_for_opponent(game_session.id, game_session.player_id)
        end
      end
    when "--list"
      if !game || !game.client.instance_variable_get(:@token)
        puts "Error: Must login first"
        exit 1
      end

      result = game.client.list_game_sessions
      unless result.success?
        puts "Error: Failed to list game sessions: #{result.error}"
        exit 1
      end
      
      sessions = result.data
      waiting_sessions = sessions.select { |s| s["status"] == "waiting" }
      if waiting_sessions.empty?
        puts "No waiting games found."
        exit
      end

      puts "\nAvailable games:"
      waiting_sessions.each do |s|
        session = GameSession.new(s)
        puts "Game #{session.id} - Created by: #{session.creator_id}"
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
  
  # If we've logged in but no other commands were provided, display_menu the interactive menu
  if game && game.client.instance_variable_get(:@token) && ARGV.length <= 3
    game.display_menu
  end
end
