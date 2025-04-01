require_relative 'client'
require_relative 'board'

class Game
  def initialize(email = nil, password = nil)
    @client = GameClient.new
    @board = Board.new
    @email = email
    @password = password
  end

  def start
    unless login
      puts "Failed to login. Exiting..."
      return
    end

    loop do
      case show_menu
      when '1'
        create_new_game
      when '2'
        join_existing_game
      when '3'
        leave_current_game
      when '4'
        register_new_player
      when '5'
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

  def create_new_game
    if @client.create_game_session
      puts "\nWaiting for another player to join..."
      wait_for_opponent
    end
  end

  def join_existing_game
    sessions = @client.list_game_sessions
    waiting_sessions = sessions.select { |s| s['status'] == 'waiting' }

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

    if @client.join_game_session(game_id)
      wait_for_opponent
    end
  end

  def wait_for_opponent
    puts "\nWaiting for opponent to join..."
    loop do
      session = @client.get_game_session
      break unless session

      case session['status']
      when 'active'
        puts "\nGame is starting!"
        play_game(session)
        break
      when 'waiting'
        if session['players'].size >= 2
          puts "\nBoth players have joined! Starting game..."
          if @client.start_game
            play_game(session)
            break
          else
            puts "Failed to start game. Please try again."
            break
          end
        else
          print "\rWaiting for opponent... (#{session['players'].size}/2 players) (Press Ctrl+C to cancel)"
          sleep 2
        end
      else
        puts "\nUnexpected game status: #{session['status']}"
        break
      end
    end
  end

  def play_game(session)
    players = session['players']
    current_player = players.find { |p| p['id'] == @client.instance_variable_get(:@player_id) }
    opponent = players.find { |p| p['id'] != @client.instance_variable_get(:@player_id) }

    puts "\nGame started! You are playing against #{opponent['name']}"
    puts "You are: #{current_player['name']}"

    loop do
      @board.display
      print "Enter position (1-9): "
      position = STDIN.gets.chomp.to_i

      if @board.make_move(position, current_player['name'])
        @board.display

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
    end
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
  case ARGV[0]
  when '--help', '-h'
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
        ruby game.rb --login email@example.com password
        ruby game.rb --create
        ruby game.rb --join 123
        ruby game.rb --list
        ruby game.rb --leave
    HELP
    exit 0
  when '--register'
    if ARGV.length != 3
      puts "Error: --register requires email and password arguments"
      puts "Usage: ruby game.rb --register email@example.com password"
      exit 1
    end
    email = ARGV[1]
    password = ARGV[2]
    game = Game.new
    if game.register_new_player(email, password)
      puts "Registration successful! You can now log in."
      game.login
    end
    exit 0
  when '--login'
    if ARGV.length != 3
      puts "Error: --login requires email and password arguments"
      puts "Usage: ruby game.rb --login email@example.com password"
      exit 1
    end
    email = ARGV[1]
    password = ARGV[2]
    game = Game.new(email, password)
    if game.login
      puts "Login successful! Starting game..."
      game.start
    else
      puts "Login failed. Please check your credentials."
      exit 1
    end
    exit 0
  when '--create'
    game = Game.new
    if game.login
      game.create_new_game
    else
      puts "Please login first."
      exit 1
    end
    exit 0
  when '--join'
    if ARGV.length != 2
      puts "Error: --join requires a session ID"
      puts "Usage: ruby game.rb --join <session_id>"
      exit 1
    end
    game = Game.new
    if game.login
      game.join_existing_game
    else
      puts "Please login first."
      exit 1
    end
    exit 0
  when '--list'
    game = Game.new
    if game.login
      sessions = game.client.list_game_sessions
      waiting_sessions = sessions.select { |s| s['status'] == 'waiting' }
      
      if waiting_sessions.empty?
        puts "No waiting games found."
        exit 0
      end

      puts "\nAvailable games:"
      waiting_sessions.each do |session|
        puts "ID: #{session['id']} - Players: #{session['players'].size}/2"
      end
    else
      puts "Please login first."
      exit 1
    end
    exit 0
  when '--leave'
    game = Game.new
    if game.login
      game.leave_current_game
    else
      puts "Please login first."
      exit 1
    end
    exit 0
  else
    puts "Error: Unknown command '#{ARGV[0]}'"
    puts "Run 'ruby game.rb --help' for usage information"
    exit 1
  end
end

# Start the game if no arguments provided
begin
  Game.new.start
rescue Interrupt
  puts "\nGame interrupted. Goodbye!"
end 