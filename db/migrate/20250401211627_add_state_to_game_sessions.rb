class AddStateToGameSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :game_sessions, :state, :jsonb
  end
end
