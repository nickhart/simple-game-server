class Game < ApplicationRecord
  has_many :game_sessions, dependent: :destroy
  has_one :game_configuration, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :state_schema, presence: true
  validates :min_players, presence: true, numericality: { greater_than: 0 }
  validates :max_players, presence: true, numericality: { greater_than: 0 }
  validate :max_players_greater_than_min_players

  def state_schema
    game_configuration&.state_schema || {}
  end

  def max_players_greater_than_min_players
    return unless min_players && max_players

    errors.add(:max_players, :must_be_greater_than_min_players) if max_players < min_players
  end
end
