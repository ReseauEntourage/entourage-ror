class CreateDonations < ActiveRecord::Migration[4.2]
  def change
    create_table :donations do |t|
      t.date    :date,                              null: false
      t.integer :amount,                            null: false
      t.string  :donation_type,                     null: false
      t.string  :reference,                         null: false
      t.string  :channel
      t.jsonb   :protected_attributes, default: [], null: false
    end
  end
end
