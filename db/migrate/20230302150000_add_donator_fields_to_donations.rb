class AddDonatorFieldsToDonations < ActiveRecord::Migration[5.2]
  def up
    add_column :donations, :sex, :string
    add_column :donations, :country, :string
    add_column :donations, :postal_code, :string
    add_column :donations, :city, :string
    add_column :donations, :payment_frequency, :string

    add_index :donations, :postal_code
  end

  def down
    remove_index :donations, :postal_code

    remove_column :donations, :sex
    remove_column :donations, :country
    remove_column :donations, :postal_code
    remove_column :donations, :city
    remove_column :donations, :payment_frequency
  end
end

