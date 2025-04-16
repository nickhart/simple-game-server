require 'json_schemer'

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
  validates :min_players, presence: true, numericality: { greater_than: 0 }, unless: :new_record?
  validates :max_players, presence: true, numericality: { greater_than: 0 }, unless: :new_record?
  validate :max_players_greater_than_min_players, unless: :new_record?
  validate :valid_status_transition
  validate :current_player_must_be_valid, if: :active?
  validate :creator_must_be_valid_player, if: :starting_game?
  validate :validate_player_count, if: :starting_game?
  validate :validate_state_against_schema, if: -> { state.present? && game&.state_json_schema.present? }

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
    self.min_players ||= game&.min_players
    self.max_players ||= game&.max_players
  end

  def max_players_greater_than_min_players
    return unless max_players.present? && min_players.present?

    errors.add(:max_players, :must_be_greater_than_or_equal_to_min_players) if max_players < min_players
  end

  def valid_status_transition
    return unless status_changed?
    return if status_was.blank?
    
    valid_transitions = {
      "waiting" => ["active"],
      "active" => ["finished"],
      "finished" => ["waiting"]
    }

    unless valid_transitions[status_was]&.include?(status)
      errors.add(:status, :invalid_status_transition, from: status_was, to: status)
    end
  end

  def current_player_must_be_valid
    return unless active?
    return if current_player_index.nil?

    errors.add(:current_player_index, :invalid_player_index) unless players[current_player_index]
  end

  def creator_must_be_valid_player
    return if creator_id.blank?

    player = Player.find_by(id: creator_id)
    unless player
      errors.add(:creator_id, :invalid_creator)
      return
    end

    errors.add(:creator_id, :creator_must_belong_to_user) unless player.user_id == Current.user&.id
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
      errors.add(:players, :too_few_players, count: game.min_players)
    elsif players.count > game.max_players
      errors.add(:players, :too_many_players, count: game.max_players)
    end
  end

  def validate_state_against_schema
    parsed_schema = JSON.parse(game.state_json_schema)
    schemer = JSONSchemer.schema(parsed_schema)
  
    validation_errors = schemer.validate(state.deep_stringify_keys).to_a
    unless validation_errors.empty?
      errors.add(:state, I18n.t("activerecord.errors.models.game_session.attributes.state.invalid_state"))
    end
  rescue JSON::ParserError => e
    errors.add(:state, "schema parsing error: #{e.message}")
  end
  
  # def validate_state_against_schema
  #   return if game.blank? || state.blank?
  
  #   puts "[DEBUG] GameSession ID: #{id || 'new'}"
  #   puts "[DEBUG] Raw state before validation: #{state.inspect}"
  #   puts "[DEBUG] Schema: #{game.state_json_schema}"
  
  #   parsed_schema = JSON.parse(game.state_json_schema)
  #   schemer = JSONSchemer.schema(parsed_schema)
  
  #   validation_errors = schemer.validate(state.deep_stringify_keys).to_a
  #   puts "[DEBUG] Schema validation errors: #{validation_errors.inspect}"
  
  #   unless validation_errors.empty?
  #     errors.add(:state, "does not match expected schema: #{validation_errors.map { |e| e['error'] }.join('; ')}")
  #   end
  # rescue => e
  #   errors.add(:state, "schema validation error: #{e.message}")
  # end
end
