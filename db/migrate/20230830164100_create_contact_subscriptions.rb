class CreateContactSubscriptions < ActiveRecord::Migration[6.1]
  def change
    create_table :contact_subscriptions do |t|
      t.string :email
      t.string :name
      t.string :profile
      t.string :subject
      t.string :message

      t.timestamps

      t.index :email, unique: true
    end
  end
end
