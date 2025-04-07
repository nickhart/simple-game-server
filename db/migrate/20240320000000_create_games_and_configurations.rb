class CreateGamesAndConfigurations < ActiveRecord::Migration[7.1]
  def change
    create_table :games do |t|
      t.string :name, null: false
      t.integer :min_players, null: false
      t.integer :max_players, null: false
      t.timestamps
    end

    add_index :games, :name, unique: true

    create_table :game_configurations do |t|
      t.references :game, null: false, foreign_key: true
      t.jsonb :state_schema, null: false, default: {}
      t.timestamps
    end

    add_column :game_sessions, :game_id, :bigint
    add_foreign_key :game_sessions, :games
  end
end 