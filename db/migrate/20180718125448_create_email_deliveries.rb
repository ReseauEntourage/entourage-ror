class CreateEmailDeliveries < ActiveRecord::Migration[4.2]
  def change
    create_table :email_deliveries do |t|
      t.integer :user_id, null: false
      t.string :campaign, null: false
      t.datetime :sent_at, null: false
      t.index [:user_id, :campaign]
    end
  end
end
