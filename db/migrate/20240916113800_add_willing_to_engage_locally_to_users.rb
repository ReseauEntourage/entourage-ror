class AddWillingToEngageLocallyToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :willing_to_engage_locally, :boolean, default: false
  end
end
