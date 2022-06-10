class RenameDisplayedToWatchedForUsersResources < ActiveRecord::Migration[5.2]
  def up
    rename_column :users_resources, :displayed, :watched
  end

  def down
    rename_column :users_resources, :watched, :displayed
  end
end
