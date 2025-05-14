require_relative "player"
require_relative "../lib/services"

class GameSession
  attr_reader :id, :game_id, :player_id, :creator_id, :status, :current_player_index, :state, :players, :board

  # Initialize a GameSession with data from the server
  def initialize(data = {})
    @id                     = data["id"]
    @game_id                = data["game_id"]
    @player_id              = data["player_id"]
    @creator_id             = data["creator_id"]
    @status                 = data["status"] || :waiting
    @current_player_index   = data["current_player_index"]
    @state                  = data["state"] || {}
    @board                  = Board.new(@state["board"])
    @players                = (data["players"] || []).map { |p| Player.new(p) }
  end

  # Check if the game is in waiting status
  def status_waiting?
    @status == :waiting
  end

  # Check if the game is active
  def status_active?
    @status == :active
  end

  # Check if the game is finished
  def status_finished?
    @status == :finished
  end

  # is the current player the creator?
  # def current_player_is_creator?
  #   @current_player_index == @creator_id
  # end

  # Get the current player object
  def current_player
    return nil if @players.empty? || @current_player_index.nil?

    @players[@current_player_index]
  end

  # Get the last move from the state
  def last_move
    @state["last_move"]
  end

  # Check if it's the current player's turn
  def my_turn?
    return false unless status_active?
    return false unless @player_id

    current_player && current_player.id == @player_id
  end

  # Check if the current player is the creator
  def am_creator?
    @player_id == @creator_id
  end

  # Get player by ID
  def player_by_id(player_id)
    @players.find { |p| p.id == player_id }
  end

  # Get player name by ID
  def player_name(player_id)
    player = player_by_id(player_id)
    player ? player.name : "Unknown"
  end

  # Join the game session with a player ID
  def join(player_id)
    Services.sessions.join(@game_id, @id)
  end

  # Start the game session
  def start
    Services.sessions.start(@game_id, @id)
  end

  # Update the game state
  def update_state(state:, status: :active, winner: nil, current_player_index: nil)
    state["winner"] = winner if winner
    attrs = {
      state: state,
      status: status
    }
    attrs[:current_player_index] = current_player_index if current_player_index
    result = Services.sessions.update(@game_id, @id, **attrs)
    return result unless result.success?
    
    # Update our instance with the response data
    data = result.data
    @status = data["status"]
    @current_player_index = data["current_player_index"]
    @state = data["state"]
    @board = Board.new(@state["board"])
    @players = (data["players"] || []).map { |p| Player.new(p) }
    
    result
  end

  # Leave the game session
  def leave
    response = Services.api_client.delete("#{route}/leave")
    Result.from_http_response(response)
  end

  # Returns the base API route for this game session
  def route
    "/api/games/#{@game_id}/sessions/#{@id}"
  end
end
