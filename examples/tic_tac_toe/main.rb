require_relative "client"
require_relative "game"
require_relative "player"
require "optparse"

class TicTacToeCLI
  def initialize
    @client = GameClient.new
    @current_player = nil
  end

  def run
    parse_options
    login
    handle_game_command
  end

  private

  def parse_options
    @options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: ruby main.rb [options]"

      opts.on("--email EMAIL", String, "Email for login") do |email|
        @options[:email] = email
      end

      opts.on("--password PASSWORD", String, "Password for login") do |password|
        @options[:password] = password
      end

      opts.on("--create", "Create a new game") do
        @options[:command] = :create
      end

      opts.on("--join [GAME_ID]", "Join an existing game (or newest waiting game)") do |game_id|
        @options[:command] = :join
        @options[:game_id] = game_id
      end

      opts.on("-h", "--help", "Show this help message") do
        puts opts
        exit
      end
    end.parse!

    # Validate that if either email or password is provided, both must be provided
    if (@options[:email] && !@options[:password]) || (!@options[:email] && @options[:password])
      puts "Error: Both --email and --password must be provided if either is used"
      exit 1
    end

    # Validate that --create and --join can only be used with login credentials
    if %i[create join].include?(@options[:command]) && !(@options[:email] && @options[:password])
      puts "Error: --create and --join can only be used with --email and --password"
      exit 1
    end
  end

  def login
    if @options[:email] && @options[:password]
      # Use command line credentials
      email = @options[:email]
      password = @options[:password]
    else
      # Prompt for credentials
      email = prompt("Enter your email: ")
      password = prompt("Enter your password: ", true)
    end

    @client.login(email, password)
    @current_player = @client.get_current_player
    puts "Logged in as #{@current_player.name}"
  end

  def handle_game_command
    case @options[:command]
    when :create
      create_game
    when :join
      join_game
    else
      show_menu
    end
  end

  def show_menu
    loop do
      puts "\nTicTacToe Menu:"
      puts "1. Create new game"
      puts "2. Join existing game"
      puts "3. List available games"
      puts "4. Exit"
      print "Choose an option: "

      case gets.chomp
      when "1"
        create_game
      when "2"
        join_game
      when "3"
        list_games
      when "4"
        exit
      else
        puts "Invalid option"
      end
    end
  end

  def create_game
    game_session = @client.create_game_session(@current_player.id, 2, 2)
    puts "Game created with ID: #{game_session.id}"
    puts "Waiting for another player to join..."

    wait_for_players(game_session)

    # Start the game after players have joined
    start_game(game_session)
  end

  def wait_for_players(game_session)
    loop do
      # Refresh the game session to get the latest player count
      result = @client.get_game_session(game_session.id)

      if result.failure?
        puts "Error refreshing game session: #{result.error}"
        sleep(2) # Wait before retrying
        next
      end

      updated_session = result.data

      if updated_session.players.size >= 2
        puts "Another player has joined! Starting the game..."
        break
      end

      print "."
      sleep(2) # Check every 2 seconds
    end
  end

  def start_game(game_session)
    # Refresh the game session to get the latest state
    updated_session = @client.get_game_session(game_session.id).data

    # Start the game on the server
    result = @client.start_game(updated_session.id, @current_player.id)

    if result.success?
      puts "Game started successfully!"
      game = Game.new(@client, result.data)
      game.play
    else
      puts "Failed to start game: #{result.error}"
    end
  end

  def join_game
    game_sessions = @client.list_game_sessions
    if game_sessions.empty?
      puts "No available games"
      return
    end

    if @options[:game_id]
      # Join specific game
      game_session = @client.join_game_session(@current_player.id, @options[:game_id])
    else
      # Join newest waiting game
      game_session = find_newest_waiting_game(game_sessions)
      return unless game_session
    end

    puts "Joined game with ID: #{game_session.id}"
    puts "Waiting for the game creator to start the game..."

    wait_for_game_start(game_session)

    # Start playing once the game has started
    game = Game.new(@client, game_session)
    game.play
  end

  def wait_for_game_start(game_session)
    loop do
      # Refresh the game session to get the latest state
      result = @client.get_game_session(game_session.id)

      if result.failure?
        puts "Error refreshing game session: #{result.error}"
        sleep(2) # Wait before retrying
        next
      end

      updated_session = result.data

      if updated_session.status == "active"
        puts "Game has started! Let's play!"
        break
      end

      print "."
      sleep(2) # Check every 2 seconds
    end
  end

  def find_newest_waiting_game(game_sessions)
    waiting_sessions = game_sessions.select { |s| s.status == "waiting" }
    if waiting_sessions.empty?
      puts "No waiting games found"
      return nil
    end
    newest_session = waiting_sessions.max_by(&:id)
    @client.join_game_session(@current_player.id, newest_session.id)
  end

  def list_games
    game_sessions = @client.list_game_sessions
    if game_sessions.empty?
      puts "No available games"
      return
    end

    puts "\nAvailable games:"
    game_sessions.each do |session|
      puts "Game #{session['id']} (#{session['players'].size}/#{session['max_players']} players)"
    end
  end

  def prompt(message, secret = false, default = nil)
    print message
    input = if secret
              `stty -echo`
              result = gets.chomp
              `stty echo`
              puts
              result
            else
              gets.chomp
            end
    input.empty? ? default : input
  end
end

# Start the CLI if this file is run directly
TicTacToeCLI.new.run if __FILE__ == $PROGRAM_NAME
