# GameSession represents a single instance of a game with its players and current state.
# It manages the lifecycle of a game from waiting for players to join,
# through active gameplay with turn management, to game completion.
class GameSession < ApplicationRecord
  belongs_to :game
  has_many :game_players, dependent: :destroy
  has_many :players, through: :game_players
  belongs_to :creator, class_name: "Player"
  has_many :users, through: :players

  enum :status, { waiting: 0, active: 1, finished: 2 }

  validates :status, presence: true, inclusion: { in: %w[waiting active finished] }
  validates :min_players, presence: true, numericality: { greater_than: 0 }
  validates :max_players, presence: true, numericality: { greater_than: 0 }
  validate :max_players_greater_than_min_players
  validate :valid_status_transition
  validate :current_player_must_be_valid
  validate :creator_must_be_valid_player, if: :starting_game?
  validate :validate_player_count
  # Temporarily disabled for development
  # validate :validate_state_schema

  before_validation :set_defaults

  def add_player(player)
    return false if active? || finished?
    return false if players.count >= max_players
    return false if players.include?(player)

    players << player
    true
  end

  def current_player
    return nil if players.empty?

    players[current_player_index]
  end

  def advance_turn
    return false unless active?

    log_turn_advancement
    update_turn_state
    save_turn_changes
  end

  def waiting?
    status == "waiting"
  end

  def active?
    status == "active"
  end

  def finished?
    status == "finished"
  end

  def start(player_id)
    log_game_start(player_id)
    return false unless valid_game_start?(player_id)

    start_game(player_id)
  end

  def finish_game
    return false unless active?

    self.status = :finished
    save
  end

  def as_json(options = {})
    super(options.merge(
      methods: [:current_player_index],
      include: {
        players: { only: %i[id name] },
        game: { only: %i[id name] }
      }
    )).merge(
      creator_id: creator_id
    )
  end

  delegate :state_schema, to: :game

  private

  def set_defaults
    self.status ||= :waiting
    self.state ||= {}
    set_default_player_limits
  end

  def set_default_player_limits
    if game
      self.min_players ||= game.min_players
      self.max_players ||= game.max_players
    else
      self.min_players ||= 2
      self.max_players ||= 2
    end
  end

  def max_players_greater_than_min_players
    return unless max_players.present? && min_players.present?

    errors.add(:max_players, "must be greater than or equal to min_players") if max_players < min_players
  end

  def valid_status_transition
    return unless status_changed?

    valid_transitions = {
      "waiting" => ["active"],
      "active" => ["finished"],
      "finished" => ["waiting"]
    }

    unless valid_transitions[status_was]&.include?(status)
      errors.add(:status, "cannot transition from #{status_was} to #{status}")
    end
  end

  def current_player_must_be_valid
    return unless active?
    return if current_player_index.nil?

    errors.add(:current_player_index, "must be a valid player index") unless players[current_player_index]
  end

  def creator_must_be_valid_player
    return if creator_id.blank?

    player = Player.find_by(id: creator_id)
    unless player
      errors.add(:creator_id, "must be a valid player")
      return
    end

    errors.add(:creator_id, "must belong to the current user") unless player.user_id == Current.user&.id
  end

  def starting_game?
    status_changed? && status == "active"
  end

  def log_turn_advancement
    Rails.logger.info "Advancing turn in game session #{id}"
    Rails.logger.info "Current player index: #{current_player_index}"
    Rails.logger.info "Current state: #{state}"
  end

  def update_turn_state
    self.current_player_index = (current_player_index + 1) % players.count
  end

  def save_turn_changes
    if save
      Rails.logger.info "Turn advanced successfully"
      Rails.logger.info "New player index: #{current_player_index}"
      Rails.logger.info "New state: #{state}"
      true
    else
      Rails.logger.error "Failed to advance turn: #{errors.full_messages.join(', ')}"
      false
    end
  end

  def log_game_start(player_id)
    Rails.logger.info "Starting game session #{id} with player #{player_id}"
    Rails.logger.info "Current status: #{status}"
    Rails.logger.info "Player count: #{players.count}"
    Rails.logger.info "Min players: #{min_players}"
    Rails.logger.info "Max players: #{max_players}"
    Rails.logger.info "Current state: #{state}"
  end

  def valid_game_start?(player_id)
    return false unless waiting?
    return false if invalid_player_count?
    return false unless player_exists?(player_id)

    true
  end

  def invalid_player_count?
    players.count < min_players || players.count > max_players
  end

  def player_exists?(player_id)
    players.exists?(id: player_id)
  end

  def start_game(player_id)
    self.status = :active
    self.current_player_index = players.to_a.index(players.find_by(id: player_id))
    save
  end

  def validate_player_count
    return unless game
    return unless starting_game?

    if players.count < game.min_players
      errors.add(:players, "must have at least #{game.min_players} players")
    elsif players.count > game.max_players
      errors.add(:players, "must have at most #{game.max_players} players")
    end
  end

  # Temporarily disabled for development
  # def validate_state_schema
  #   return unless game && state.present?
  #
  #   schema = game.state_schema
  #   return if schema.blank?
  #
  #   validate_schema(state, schema)
  # end

  # def validate_schema(data, schema, path = [])
  #   case schema["type"]
  #   when "object"
  #     validate_object(data, schema, path)
  #   when "array"
  #     validate_array(data, schema, path)
  #   when String
  #     validate_primitive(data, schema, path)
  #   when Array
  #     validate_multiple_types(data, schema, path)
  #   end
  # end
end
