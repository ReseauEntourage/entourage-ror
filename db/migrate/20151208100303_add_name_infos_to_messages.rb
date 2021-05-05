class AddNameInfosToMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :messages, :first_name, :string, null: true
    add_column :messages, :last_name, :string, null: true
    add_column :messages, :email, :string, null: true
  end
end
