class DropGamePlayers < ActiveRecord::Migration[7.1]
  def change
    drop_table :game_players, if_exists: true
  end
end 