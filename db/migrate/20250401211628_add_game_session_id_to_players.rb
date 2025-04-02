class AddGameSessionIdToPlayers < ActiveRecord::Migration[7.1]
  def change
    add_reference :players, :game_session, null: true, foreign_key: true
  end
end 