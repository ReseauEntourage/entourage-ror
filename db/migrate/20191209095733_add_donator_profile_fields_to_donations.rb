class AddDonatorProfileFieldsToDonations < ActiveRecord::Migration
  def change
    add_column :donations, :first_time_donator, :boolean, null: false, default: false
    add_column :donations, :app_user_id, :integer
  end
end
