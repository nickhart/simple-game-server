require_relative "player"

class GameSession
  attr_reader :id, :player_id, :creator_id, :status, :current_player_index, :state, :players, :board

  # Initialize a GameSession with data from the server
  def initialize(data = {})
    @id = data["id"]
    @player_id = data["player_id"]
    @creator_id = data["creator_id"]
    @status = data["status"] || :waiting
    @current_player_index = data["current_player_index"]
    @state = data["state"] || {}
    @board = Board.new(@state["board"])
    @players = (data["players"] || []).map { |p| Player.new(p) }
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
  def current_player_is_creator?
    @current_player_index == @creator_id
  end

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
end
