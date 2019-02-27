class AddTargetingProfileToUsers < ActiveRecord::Migration
  def change
    add_column :users, :targeting_profile, :string
  end
end
