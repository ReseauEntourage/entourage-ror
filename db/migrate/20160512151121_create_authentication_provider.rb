class CreateAuthenticationProvider < ActiveRecord::Migration[4.2]
  def change
    create_table :authentication_providers do |t|
      t.integer :user_id, null: false
      t.string  :provider, null: false
      t.integer :provider_id, null: false
      t.string  :type, null: false

      t.timestamps null: false
    end

    add_index :authentication_providers, [:user_id, :provider], unique: true
  end
end
