class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    unless table_exists?(:players)
      create_table :players do |t|
        t.string :name
        t.references :game_session, null: false, foreign_key: true
        t.references :user, null: false, foreign_key: true

        t.timestamps
      end

      add_index :players, :game_session_id
      add_index :players, :user_id
    end
  end
end
