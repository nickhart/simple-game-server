class Player < ApplicationRecord
  has_many :game_players, dependent: :destroy
  has_many :game_sessions, through: :game_players

  validates :name, presence: true
end
