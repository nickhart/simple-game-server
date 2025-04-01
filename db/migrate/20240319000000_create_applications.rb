class CreateApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :applications do |t|
      t.string :name
      t.string :api_key
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :applications, :api_key, unique: true
    add_index :applications, :active
  end
end 