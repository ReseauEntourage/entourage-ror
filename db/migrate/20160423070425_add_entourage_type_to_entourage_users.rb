class AddEntourageTypeToEntourageUsers < ActiveRecord::Migration
  def change
    add_column :entourages_users, :entourage_type, :string, null: false
  end
end
