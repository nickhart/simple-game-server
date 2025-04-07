class UpdatePlayersToUseUuid < ActiveRecord::Migration[8.0]
  def up
    # Enable pgcrypto extension for UUID support
    enable_extension 'pgcrypto'

    # Create a temporary column for UUID
    add_column :players, :uuid, :uuid, default: 'gen_random_uuid()'

    # If there's a game_players table referencing players
    if table_exists?(:game_players)
      # Remove the foreign key if it exists
      remove_foreign_key :game_players, :players if foreign_key_exists?(:game_players, :players)
      
      # Add UUID column to game_players
      add_column :game_players, :player_uuid, :uuid
      
      # Copy the relationships using the old IDs
      execute <<-SQL
        UPDATE game_players
        SET player_uuid = players.uuid
        FROM players
        WHERE game_players.player_id = players.id
      SQL
      
      # Remove old player_id column
      remove_column :game_players, :player_id
      
      # Rename UUID column to player_id
      rename_column :game_players, :player_uuid, :player_id
    end

    # Update game_sessions table if it references players
    if table_exists?(:game_sessions) && column_exists?(:game_sessions, :creator_id)
      add_column :game_sessions, :creator_uuid, :uuid
      
      execute <<-SQL
        UPDATE game_sessions
        SET creator_uuid = players.uuid
        FROM players
        WHERE game_sessions.creator_id = players.id
      SQL
      
      remove_column :game_sessions, :creator_id
      rename_column :game_sessions, :creator_uuid, :creator_id
    end

    # Remove the old id column and rename uuid to id
    remove_column :players, :id
    rename_column :players, :uuid, :id
    execute 'ALTER TABLE players ADD PRIMARY KEY (id);'

    # Add back foreign keys with UUID
    if table_exists?(:game_players)
      add_foreign_key :game_players, :players, column: :player_id, primary_key: :id
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end 