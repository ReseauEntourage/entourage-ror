class AddInterestsToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :interests, :jsonb, default: [], null: false
  end
end
