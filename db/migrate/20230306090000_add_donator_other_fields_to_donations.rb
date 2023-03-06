class AddDonatorOtherFieldsToDonations < ActiveRecord::Migration[5.2]
  def up
    add_column :donations, :payment_type, :string
    add_column :donations, :donator_birthdate, :date
    add_column :donations, :iraiser_donator_id, :integer
    add_column :donations, :donator_iraiser_account_creation_date, :date
    add_column :donations, :donation_once_last_date, :date
    add_column :donations, :donation_regular_first_date, :date
    add_column :donations, :donator_donation_regular_last_date, :date
    add_column :donations, :donator_donation_regular_last_year_total, :integer
    add_column :donations, :donator_donation_regular_amount, :integer

    add_index :donations, :iraiser_donator_id
  end

  def down
    remove_index :donations, :iraiser_donator_id

    remove_column :donations, :payment_type, :string
    remove_column :donations, :donator_birthdate, :date
    remove_column :donations, :iraiser_donator_id, :integer
    remove_column :donations, :donator_iraiser_account_creation_date, :date
    remove_column :donations, :donation_once_last_date, :date
    remove_column :donations, :donation_regular_first_date, :date
    remove_column :donations, :donator_donation_regular_last_date, :date
    remove_column :donations, :donator_donation_regular_last_year_total, :integer
    remove_column :donations, :donator_donation_regular_amount, :integer
  end
end
