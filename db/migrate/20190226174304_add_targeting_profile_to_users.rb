class AddTargetingProfileToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :targeting_profile, :string
  end
end
