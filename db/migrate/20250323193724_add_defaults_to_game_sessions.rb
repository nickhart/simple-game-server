class AddDefaultsToGameSessions < ActiveRecord::Migration[8.0]
  def change
    change_column_default :game_sessions, :min_players, from: nil, to: 2
    change_column_default :game_sessions, :max_players, from: nil, to: 4
    change_column_default :game_sessions, :status, from: nil, to: 0
    change_column_null :game_sessions, :min_players, false
    change_column_null :game_sessions, :max_players, false
    change_column_null :game_sessions, :status, false
  end
end
