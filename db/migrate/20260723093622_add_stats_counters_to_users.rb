class AddStatsCountersToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :entourages_count, :integer, default: 0, null: false
    add_column :users, :actions_count, :integer, default: 0, null: false
    add_column :users, :outings_count, :integer, default: 0, null: false
    add_column :users, :neighborhoods_count, :integer, default: 0, null: false
  end
end
