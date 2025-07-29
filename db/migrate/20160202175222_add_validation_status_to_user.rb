class AddValidationStatusToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :validation_status, :string, null: false, default: 'validated'
  end
end
