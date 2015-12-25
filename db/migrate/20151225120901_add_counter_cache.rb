class AddCounterCache < ActiveRecord::Migration
  def change
    add_column :tours, :encounters_count, :integer, default: 0, null: false
  end
end
