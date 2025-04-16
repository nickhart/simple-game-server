class Game < ApplicationRecord
  has_many :game_sessions, dependent: :destroy
 
  validates :name, presence: true, uniqueness: true
  validates :state_json_schema, presence: true
  validates :min_players, presence: true, numericality: { greater_than_or_equal_to: 2 }
  validates :max_players, presence: true, numericality: { less_than_or_equal_to: 10 }
  validate :max_players_greater_than_min_players

  def max_players_greater_than_min_players
    return unless min_players && max_players

    errors.add(:max_players, :must_be_greater_than_min_players) if max_players < min_players
  end
end
