class AddOtherInterestToUsersAndNeighborhoods < ActiveRecord::Migration[5.2]
  def up
    add_column :neighborhoods, :other_interest, :string
    add_column :users, :other_interest, :string
  end

  def down
    remove_column :neighborhoods, :other_interest
    remove_column :users, :other_interest
  end
end
