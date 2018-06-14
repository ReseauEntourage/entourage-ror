class CreateActionZones < ActiveRecord::Migration
  def change
    create_table :action_zones do |t|
      t.references :user, index: true, foreign_key: true, null: false
      t.string :postal_code, limit: 5, null: false
      t.string :country, limit: 2, null: false

      t.timestamps null: false
    end

    add_index :action_zones, [:country, :postal_code, :user_id], unique: true
  end
end
