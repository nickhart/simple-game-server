class Game < ApplicationRecord
  # Maximum number of players allowed in a game
  # This is an arbitrary limit that can be increased if needed
  MAX_PLAYERS = 10

  has_many :game_sessions, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :min_players, presence: true, numericality: { greater_than: 0 }
  validates :max_players, presence: true, numericality: { less_than_or_equal_to: MAX_PLAYERS }
  validate :max_players_greater_than_min_players

  private

  def max_players_greater_than_min_players
    return unless min_players && max_players

    errors.add(:max_players, "must be greater than or equal to min_players") if max_players < min_players
  end
end
