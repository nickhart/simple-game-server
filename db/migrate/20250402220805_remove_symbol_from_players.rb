class RemoveSymbolFromPlayers < ActiveRecord::Migration[8.0]
  def change
    remove_column :players, :symbol, :string
  end
end
