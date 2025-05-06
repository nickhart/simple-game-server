require_relative "../lib/services"
require_relative "../lib/api_client"
require_relative "../lib/config_loader"
require_relative "../lib/clients/tokens_client"
require_relative "../lib/clients/games_client"
require_relative "../lib/services"
require_relative "game"
require_relative "game_session"
require_relative "player"
require "optparse"

CONFIG = ConfigLoader.load!(%w[game_name], config_dir: __dir__)
GAME_NAME = CONFIG["game_name"]

class TicTacToeCLI
  def initialize
    @current_player = nil
    @game_id = nil
  end

  def run
    parse_options
    login
    set_game_id
    handle_game_command
  end

  private

  def parse_options
    @options = {}
    setup_option_parser
    validate_options
  end

  def setup_option_parser
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
  end

  def validate_options
    validate_credentials
    validate_command_requirements
  end

  def validate_credentials
    return unless credentials_partially_provided?

    puts "Error: Both --email and --password must be provided if either is used"
    exit 1
  end

  def validate_command_requirements
    return unless command_requires_credentials?

    puts "Error: --create and --join can only be used with --email and --password"
    exit 1
  end

  def credentials_partially_provided?
    (@options[:email] && !@options[:password]) || (!@options[:email] && @options[:password])
  end

  def command_requires_credentials?
    %i[create join].include?(@options[:command]) && !(@options[:email] && @options[:password])
  end

  def login
    if @options[:email] && @options[:password]
      email = @options[:email]
      password = @options[:password]
    else
      email = prompt("Enter your email: ")
      password = prompt("Enter your password: ", secret: true)
    end

    # Perform authentication to get JWT
    raw_api = ApiClient.new(CONFIG["api_url"])
    auth_client = TokensClient.new(raw_api)
    token_result = auth_client.login(email, password)
    return puts "Login failed: #{token_result.error}" if token_result.failure?

    Services.setup(api_url: CONFIG["api_url"], token: token_result.data)

    current_result = Services.players.me
    return puts "Could not fetch current player: #{current_result.error}" if current_result.failure?

    @current_player = current_result.data
    puts "Logged in as #{@current_player.inspect}"
  end

  def set_game_id
    games = GamesClient.new(Services.api_client)
    result = games.find_by_name(GAME_NAME)
    if result.failure?
      puts "Error: Could not find game named '#{GAME_NAME}'. Reason: #{result.error}"
      exit 1
    end
    @game_id = result.data["id"]
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
    result = Services.sessions.create(@game_id)
    return puts "Error creating game session: #{result.error}" if result.failure?

    game_session = GameSession.new(result.data)
    puts "game_session: #{game_session}"
    puts "Game created with ID: #{game_session.id}"
    puts "Waiting for another player to join..."

    wait_for_players(game_session)

    # Start the game after players have joined
    start_game(game_session)
  end

  def wait_for_players(game_session)
    loop do
      # Refresh the game session to get the latest player count
      result = Services.sessions.get(game_session.game_id, game_session.id)

      if result.failure?
        puts "Error refreshing game session: #{result.error}"
        sleep(2) # Wait before retrying
        next
      end

      updated_session = GameSession.new(result.data)

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
    result = Services.sessions.get(game_session.game_id, game_session.id)
    return puts "Error refreshing game session: #{result.error}" if result.failure?

    game_session = GameSession.new(result.data)

    # Start the game on the server
    start_result = Services.sessions.start(game_session.game_id, game_session.id)
    return puts "Failed to start game: #{start_result.error}" if start_result.failure?

    game_session = GameSession.new(start_result.data)

    if game_session.status == "active"
      puts "Game started successfully!"
      game = Game.new(game_session)
      game.play
    else
      puts "Failed to start game: #{game_session.inspect}"
    end
  end

  def join_game
    result = Services.sessions.list(@game_id)
    return puts "Error listing game sessions: #{result.error}" if result.failure?

    sessions_array = result.data  
    game_sessions = sessions_array.map do |session_data|
      GameSession.new(session_data)
    end

    game_session = if @options[:game_id]
                    game_sessions.find { |s| s.id.to_s == @options[:game_id].to_s }
                   else
                    game_sessions.select { |s| s.status == "waiting" }.max_by(&:id)
                   end

    unless game_session
      puts "No available matching game session to join"
      return
    end

    join_result = Services.sessions.join(@game_id, game_session.id)
    return puts "Failed to join game session: #{join_result.error}" if join_result.failure?

    game_session = GameSession.new(join_result.data)
    puts "Joined game with ID: #{game_session.id}"
    puts "Waiting for the game creator to start the game..."

    wait_for_game_start(game_session)

    # Start playing once the game has started
    game = Game.new(game_session)
    game.play
  end

  def wait_for_game_start(game_session)
    loop do
      # Refresh the game session to get the latest state
      result = Services.sessions.get(game_session.game_id, game_session.id)

      if result.failure?
        puts "Error refreshing game session: #{result.error}"
        sleep(2) # Wait before retrying
        next
      end

      updated_session = GameSession.new(result.data)

      if updated_session.status == "active"
        puts "Game has started! Let's play!"
        break
      end

      print "."
      sleep(2) # Check every 2 seconds
    end
  end

  def list_games
    result = Services.sessions.list(@game_id)
    return puts "Error listing games: #{result.error}" if result.failure?

    game_sessions = result.data
    if game_sessions.empty?
      puts "No available games"
      return
    end

    puts "\nAvailable games:"
    game_sessions.each do |session_data|
      session = GameSession.new(session_data)
      puts "Game #{session.id} (#{session.players.size} players)"
    end
  end

  def prompt(message, secret: false, default: nil)
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
