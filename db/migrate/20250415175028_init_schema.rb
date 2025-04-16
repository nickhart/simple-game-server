class InitSchema < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :encrypted_password, null: false
      t.string :role, null: false, default: 'player'
      t.jsonb :tokens, null: false, default: {}
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer :token_version, null: false, default: 1
      t.timestamps
    end
    add_index :users, :reset_password_token, unique: true

    create_table :tokens do |t|
      t.string :jti, null: false
      t.string :token_type, null: false
      t.datetime :expires_at, null: false
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    add_index :tokens, :jti, unique: true

    create_table :players do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.timestamps
    end

    create_table :games do |t|
      t.string :name, null: false
      t.text :state_json_schema
      t.integer :min_players, default: 2
      t.integer :max_players, default: 10
      t.timestamps
    end
    add_index :games, :name, unique: true

    create_table :game_sessions do |t|
      t.references :game, foreign_key: true
      t.references :creator, foreign_key: { to_table: :players }
      t.integer :min_players
      t.integer :max_players
      t.string :name, default: ""
      t.string :status, default: "waiting"
      t.jsonb :state, default: {}
      t.timestamps
    end

    create_join_table :game_sessions, :players do |t|
      t.index [:game_session_id, :player_id], unique: true
    end
  end
end