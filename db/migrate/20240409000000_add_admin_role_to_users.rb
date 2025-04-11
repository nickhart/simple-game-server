class AddAdminRoleToUsers < ActiveRecord::Migration[7.1]
  def change
    # Add admin role to existing users table
    add_column :users, :role, :string, default: "player", null: false unless column_exists?(:users, :role)
    
    # Add index for role
    add_index :users, :role unless index_exists?(:users, :role)
    
    # Add admin boolean flag for quick admin checks
    add_column :users, :is_admin, :boolean, default: false, null: false unless column_exists?(:users, :is_admin)
    
    # Add index for admin flag
    add_index :users, :is_admin unless index_exists?(:users, :is_admin)
  end
end 