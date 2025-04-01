class CreateGameSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :game_sessions do |t|
      t.integer :status, default: 0  # 0: waiting, 1: active, 2: finished
      t.integer :min_players, default: 2
      t.integer :max_players, default: 2
      t.integer :current_player_index, default: 0
      t.jsonb :state, default: {}  # Generic game state storage
      t.integer :creator_id  # ID of the player who created the game

      t.timestamps
    end
  end
end
