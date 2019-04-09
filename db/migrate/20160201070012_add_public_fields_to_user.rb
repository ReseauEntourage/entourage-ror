class AddPublicFieldsToUser < ActiveRecord::Migration
  def up
    change_column :users, :organization_id, :integer, null: true
    add_column :users, :user_type, :string, null: false, default: "pro"
  end

  def down
  end
end
