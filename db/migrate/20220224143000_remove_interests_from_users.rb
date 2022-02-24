class RemoveInterestsFromUsers < ActiveRecord::Migration[5.2]
  def up
    remove_column :users, :interests
  end

  def down
    add_column :users, :interests, :string
  end
end
