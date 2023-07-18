class AddOptionsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :options, :json, default: {}
  end
end
