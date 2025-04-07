class AddCreatorIdToGameSessions < ActiveRecord::Migration[7.0]
  def change
    add_column :game_sessions, :creator_id, :integer
    add_index :game_sessions, :creator_id
  end
end 