class AddAboutToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :about, :string, limit: 200, null: true
  end
end
