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

  private

  def login
    if @email && @password
      @client.login(@email, @password)
    else
      print "Email: "
      email = gets.chomp
      print "Password: "
      password = gets.chomp
      @client.login(email, password)
    end
  end

  def show_menu
    puts "\n=== Tic Tac Toe ==="
    puts "1. Create new game"
    puts "2. Join existing game"
    puts "3. Leave current game"
    puts "4. Register new player"
    puts "5. Exit"
    print "\nChoice: "
    gets.chomp
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
    game_id = gets.chomp.to_i

    if @client.join_game_session(game_id)
      wait_for_opponent
    end
  end

  def wait_for_opponent
    loop do
      session = @client.get_game_session
      break unless session

      if session['status'] == 'active'
        play_game(session)
        break
      end

      # If we have enough players and we're the creator, start the game
      if session['status'] == 'waiting' && session['players'].size >= 2
        if @client.start_game
          play_game(session)
          break
        end
      end

      puts "Waiting for opponent... (Press Ctrl+C to cancel)"
      sleep 2
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
      position = gets.chomp.to_i

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
    email = gets.chomp
    print "Password: "
    password = gets.chomp
    print "Confirm Password: "
    confirm_password = gets.chomp

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
if ARGV[0] == '--register'
  if ARGV.length != 3
    puts "Usage: ruby game.rb --register email password"
    exit 1
  end
  email = ARGV[1]
  password = ARGV[2]
  
  # Create a new client and attempt to register
  client = GameClient.new
  
  # First try to login to get a token
  if client.login(email, password)
    puts "Player already exists. Please use:"
    puts "ruby game.rb #{email} #{password}"
    exit 0
  end
  
  # If login failed, try to register
  if client.register(email, password)
    puts "Registration successful! You can now log in with:"
    puts "ruby game.rb #{email} #{password}"
  else
    puts "Registration failed. Please try again."
    exit 1
  end
  exit 0
else
  email = ARGV[0]
  password = ARGV[1]
end

# Start the game
begin
  Game.new(email, password).start
rescue Interrupt
  puts "\nGame interrupted. Goodbye!"
end 