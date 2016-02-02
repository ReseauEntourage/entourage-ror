class AddValidationStatusToUser < ActiveRecord::Migration
  def change
    add_column :users, :validation_status, :string, null: false, default: "validated"
  end
end
