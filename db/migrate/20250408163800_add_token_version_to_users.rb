class AddTokenVersionToUsers < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:users, :token_version)
      add_column :users, :token_version, :integer, default: 0
    end
  end
end
