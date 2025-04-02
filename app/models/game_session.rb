# GameSession represents a single instance of a game with its players and current state.
# It manages the lifecycle of a game from waiting for players to join,
# through active gameplay with turn management, to game completion.
class GameSession < ApplicationRecord
  has_many :players, dependent: :destroy
  has_many :users, through: :players

  enum :status, { waiting: 0, active: 1, finished: 2 }

  validates :status, presence: true
  validates :min_players, presence: true, numericality: { greater_than: 0 }
  validates :max_players, presence: true, numericality: { greater_than: 0 }
  validate :max_players_greater_than_min_players
  validate :valid_status_transition

  before_validation :set_defaults

  def add_player(user)
    return false if active? || finished?
    return false if players.count >= max_players
    players.create(user: user)
  end

  def current_player
    return nil if players.empty?
    players[current_player_index]
  end

  def advance_turn
    return false unless active?
    Rails.logger.info "Advancing turn in game session #{id}"
    Rails.logger.info "Current player index: #{current_player_index}"
    Rails.logger.info "Current state: #{state}"

    # Update the state JSON with the new player index
    self.state['current_player_index'] = (current_player_index + 1) % players.count
    self.current_player_index = self.state['current_player_index']

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

  def waiting?
    status == 'waiting'
  end

  def active?
    status == 'active'
  end

  def finished?
    status == 'finished'
  end

  def start(player_id)
    Rails.logger.info "Starting game session #{id} with player #{player_id}"
    Rails.logger.info "Current status: #{status}"
    Rails.logger.info "Player count: #{players.count}"
    Rails.logger.info "Min players: #{min_players}"
    Rails.logger.info "Max players: #{max_players}"
    Rails.logger.info "Current state: #{state}"

    unless waiting?
      Rails.logger.info "Game is not in waiting status"
      return false
    end

    if players.count < min_players || players.count > max_players
      Rails.logger.info "Invalid player count: #{players.count} (min: #{min_players}, max: #{max_players})"
      return false
    end

    player = players.find_by(id: player_id)
    unless player
      Rails.logger.info "Player #{player_id} not found in game"
      return false
    end

    Rails.logger.info "All conditions met, starting game"
    self.status = :active
    self.current_player_index = players.to_a.index(player)

    # Initialize the game state as JSON
    self.state = {}

    if save
      Rails.logger.info "Game started successfully"
      Rails.logger.info "Initial player index: #{current_player_index}"
      Rails.logger.info "Initial state: #{state}"
      true
    else
      Rails.logger.info "Failed to save game: #{errors.full_messages.join(', ')}"
      false
    end
  end

  def finish_game
    return false unless active?
    self.status = :finished
    save
  end

  private

  def set_defaults
    self.status ||= :waiting
    self.min_players ||= 2
    self.max_players ||= 2
    self.state ||= {}
  end

  def max_players_greater_than_min_players
    if max_players < min_players
      errors.add(:max_players, "must be greater than or equal to min_players")
    end
  end

  def valid_status_transition
    return unless status_changed?

    Rails.logger.info "Validating status transition from #{status_was} to #{status}"

    valid_transitions = {
      "waiting" => [ "active" ],
      "active" => [ "finished" ],
      "finished" => [ "waiting" ]
    }

    unless valid_transitions[status_was]&.include?(status)
      Rails.logger.info "Invalid transition: from #{status_was} to #{status}"
      Rails.logger.info "Valid transitions for #{status_was}: #{valid_transitions[status_was]}"
      errors.add(:status, "cannot transition from #{status_was} to #{status}")
    else
      Rails.logger.info "Valid transition: from #{status_was} to #{status}"
    end
  end
end
