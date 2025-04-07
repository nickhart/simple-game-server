class Game < ApplicationRecord
  has_many :game_sessions
  has_one :game_configuration, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :min_players, presence: true, numericality: { greater_than: 0 }
  validates :max_players, presence: true, numericality: { greater_than_or_equal_to: :min_players }

  def state_schema
    game_configuration&.state_schema || {}
  end
end
