class AddAvatarToUser < ActiveRecord::Migration
  def change
    add_column :users, :avatar_key, :string, null: true
  end
end
