class AddAboutToUsers < ActiveRecord::Migration
  def change
    add_column :users, :about, :string, limit: 200, null: true
  end
end
