require_relative "player"

class GameSession
  attr_reader :id, :player_id, :creator_id, :status, :current_player_index, :state, :players

  # Initialize a GameSession with data from the server
  def initialize(data = {})
    @id = data["id"]
    @player_id = data["player_id"]
    @creator_id = data["creator_id"]
    @status = data["status"] || "waiting"
    @current_player_index = data["current_player_index"]
    @state = data["state"] || {}
    @players = (data["players"] || []).map { |p| Player.new(p) }

    # If player_id is not set and we have players, assign it
    # For game creation, assume it's the first player
    # For joining, assume it's the last player
    if @player_id.nil? && !@players.empty?
      @player_id = if @creator_id.nil?
                     # This is a new game, so the player_id is the first player
                     @players.first.id
                   else
                     # This is joining an existing game, so the player_id is the last player
                     # TODO: This is a hacky way to assign the player_id. A more robust solution
                     # would be to have the server return the player_id in the response.
                     @players.last.id
                   end
    end
  end

  # Check if the game is in waiting status
  def waiting?
    @status == "waiting"
  end

  # Check if the game is active
  def active?
    @status == "active"
  end

  # Check if the game is finished
  def finished?
    @status == "finished"
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

  # Get the board from the state
  def board
    @state["board"] || Array.new(9, 0)
  end

  # Get the last move from the state
  def last_move
    @state["last_move"]
  end

  # Check if it's the current player's turn
  def my_turn?
    return false unless active?
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
