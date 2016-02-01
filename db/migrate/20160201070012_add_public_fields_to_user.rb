class AddPublicFieldsToUser < ActiveRecord::Migration
  def change
    change_column :users, :organization_id, :integer, null: true
  end
end
