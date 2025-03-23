class GamePlayer < ApplicationRecord
  belongs_to :game_session
  belongs_to :player

  validates :player_id, uniqueness: { scope: :game_session_id, message: "is already in this game session" }
end
