class GameSession < ApplicationRecord
  has_many :game_players, dependent: :destroy
  has_many :players, through: :game_players

  enum :status, { waiting: 0, active: 1, finished: 2 }

  validates :min_players, presence: true, numericality: { greater_than: 0 }
  validates :max_players, presence: true, numericality: { greater_than_or_equal_to: :min_players }
  validates :status, presence: true
  validate :player_count_within_limits

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
end
