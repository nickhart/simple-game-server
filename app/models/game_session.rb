# GameSession represents a single instance of a game with its players and current state.
# It manages the lifecycle of a game from waiting for players to join,
# through active gameplay with turn management, to game completion.
class GameSession < ApplicationRecord
  has_many :game_players, dependent: :destroy
  has_many :players, through: :game_players

  enum :status, { waiting: 0, active: 1, finished: 2 }

  validates :min_players, presence: true
  validates :max_players, presence: true
  validates :min_players, numericality: { greater_than: 0, only_integer: true }, if: -> { min_players.present? }
  validates :max_players, numericality: { greater_than_or_equal_to: :min_players, only_integer: true }, if: -> { max_players.present? && min_players.present? }
  validates :status, presence: true
  validate :player_count_within_limits
  validate :valid_state_transition

  before_validation :set_default_status
  before_save :initialize_current_player_index, if: :status_changed_to_active?

  def add_player(player)
    return false if active? || finished?
    return false if players.count >= max_players

    game_players.create(player: player)
  end

  def start_game
    return false unless can_start?

    update(status: :active)
  end

  def advance_turn
    return false unless active?

    next_index = (current_player_index + 1) % players.count
    update(current_player_index: next_index)
  end

  def current_player
    return nil unless active?
    players.order(:created_at)[current_player_index]
  end

  def finish_game
    return false unless active?
    update(status: :finished)
  end

  private

  def set_default_status
    self.status ||= :waiting
  end

  def can_start?
    waiting? && players.count >= min_players && players.count <= max_players
  end

  def player_count_within_limits
    return unless active?

    if players.count < min_players
      errors.add(:base, "Not enough players to start the game")
    elsif players.count > max_players
      errors.add(:base, "Too many players in the game")
    end
  end

  def status_changed_to_active?
    status_changed? && active?
  end

  def initialize_current_player_index
    self.current_player_index = 0
  end

  def valid_state_transition
    return unless status_changed?
    return if status_was.nil? # Allow initial status setting

    valid_transitions = {
      'waiting' => ['active'],
      'active' => ['finished'],
      'finished' => []
    }

    unless valid_transitions[status_was]&.include?(status)
      errors.add(:status, "cannot transition from #{status_was} to #{status}")
    end
  end
end
