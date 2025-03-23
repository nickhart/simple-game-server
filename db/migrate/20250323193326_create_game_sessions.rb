class CreateGameSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :game_sessions do |t|
      t.integer :status
      t.integer :min_players
      t.integer :max_players
      t.integer :current_player_index

      t.timestamps
    end
  end
end
