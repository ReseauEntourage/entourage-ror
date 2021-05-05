class AddAvatarToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :avatar_key, :string, null: true
  end
end
