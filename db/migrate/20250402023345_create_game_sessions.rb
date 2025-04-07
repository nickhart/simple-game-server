class CreateGameSessions < ActiveRecord::Migration[8.0]
  def change
    unless table_exists?(:game_sessions)
      create_table :game_sessions do |t|
        t.integer :status, default: 0, null: false
        t.integer :min_players, default: 2, null: false
        t.integer :max_players, default: 4, null: false
        t.integer :current_player_index
        t.string :game_type, default: "default", null: false
        t.jsonb :state

        t.timestamps
      end
    end
  end
end
