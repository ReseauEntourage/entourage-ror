class AddInterestsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :interests, :jsonb, default: [], null: false
  end
end
