class AddUniqueIndexToGamePlayers < ActiveRecord::Migration[7.1]
  def change
    add_index :game_players, [:player_id, :game_session_id], unique: true
  end
end
