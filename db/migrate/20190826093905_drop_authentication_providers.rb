class DropAuthenticationProviders < ActiveRecord::Migration
  def up
    drop_table :authentication_providers
  end

  def down
    create_table :authentication_providers do |t|
      t.integer  :user_id,     null: false
      t.string   :provider,    null: false
      t.integer  :provider_id, null: false
      t.string   :type,        null: false
      t.timestamps             null: false
    end

    add_index :authentication_providers, [:user_id, :provider], unique: true
  end
end
