class CreateSmsDeliveries < ActiveRecord::Migration[4.2]
  def change
    create_table :sms_deliveries do |t|
      t.string :phone_number
      t.integer :status
      t.string :sms_type

      t.timestamps null: false
    end
  end
end
