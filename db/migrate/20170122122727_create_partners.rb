class CreatePartners < ActiveRecord::Migration[4.2]
  def change
    create_table :partners do |t|
      t.string :name,             null: false
      t.string :large_logo_url,   null: false
      t.string :small_logo_url,   null: false
      t.timestamps                null: false
    end

    create_table :user_partners do |t|
      t.integer :user_id,         null: false
      t.integer :partner_id,      null: false
      t.boolean :default,         null: false, default: false
      t.timestamps                null: false
    end

    add_index :user_partners, [:user_id, :partner_id], unique: true
  end
end
