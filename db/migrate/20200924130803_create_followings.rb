class CreateFollowings < ActiveRecord::Migration[4.2]
  def change
    create_table :followings do |t|
      t.integer :user_id, null: false
      t.integer :partner_id, null: false
      t.boolean :active, null: false, default: true
      t.index [:user_id, :partner_id], unique: true
      t.index :partner_id
    end
  end
end
