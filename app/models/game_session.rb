# GameSession represents a single instance of a game with its players and current state.
# It manages the lifecycle of a game from waiting for players to join,
# through active gameplay with turn management, to game completion.
class GameSession < ApplicationRecord
  has_many :game_players, dependent: :destroy
  has_many :players, through: :game_players

  validates :min_players, presence: true, numericality: { greater_than: 0 }
  validates :max_players, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true
  validate :max_players_must_be_greater_than_min_players
  validate :validate_state_transition, if: :status_changed?

  enum :status, [:waiting, :active, :finished]

  before_save :initialize_current_player_index, if: :becoming_active?

  def add_player(player)
    return false if active? || finished?
    return false if game_players.count >= max_players
    game_players.create(player: player)
  end

  def start_game
    return false unless can_start?
    self.status = :active
    save
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
    self.status = :finished
    save
  end

  private

  def max_players_must_be_greater_than_min_players
    return unless min_players.present? && max_players.present?
    if max_players < min_players
      errors.add(:max_players, "must be greater than or equal to min players")
    end
  end

  def validate_state_transition
    return if status.nil? # Let presence validation handle nil status
    return unless status_was # Allow setting initial status
    
    case status_was.to_sym
    when :waiting
      if active?
        if game_players.count < min_players
          errors.add(:status, "cannot transition to active with insufficient players")
        end
      else
        errors.add(:status, "can only transition from waiting to active")
      end
    when :active
      unless finished?
        errors.add(:status, "can only transition from active to finished")
      end
    when :finished
      errors.add(:status, "cannot transition from finished state")
    end
  end

  def can_start?
    waiting? && game_players.count >= min_players
  end

  def becoming_active?
    status_changed? && active?
  end

  def initialize_current_player_index
    self.current_player_index = 0
  end
end
