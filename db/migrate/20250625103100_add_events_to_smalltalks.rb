class AddEventsToSmalltalks < ActiveRecord::Migration[6.1]
  def change
    add_column :smalltalks, :events, :json, default: {}
  end
end
