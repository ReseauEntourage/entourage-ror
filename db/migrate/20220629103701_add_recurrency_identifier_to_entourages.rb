class AddRecurrencyIdentifierToEntourages < ActiveRecord::Migration[5.2]
  def up
    add_column :entourages, :recurrency_identifier, :string
  end

  def down
    remove_column :entourages, :recurrency_identifier
  end
end

