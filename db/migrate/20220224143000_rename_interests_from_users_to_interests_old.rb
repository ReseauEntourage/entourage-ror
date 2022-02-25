class RenameInterestsFromUsersToInterestsOld < ActiveRecord::Migration[5.2]
  def up
    rename_column :users, :interests, :interests_old
  end

  def down
    rename_column :users, :interests_old, :interests
  end
end
