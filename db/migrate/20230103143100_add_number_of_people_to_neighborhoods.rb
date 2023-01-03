class AddNumberOfPeopleToNeighborhoods < ActiveRecord::Migration[5.2]
  def up
    add_column :neighborhoods, :number_of_people, :integer, default: 0
  end

  def down
    remove_column :neighborhoods, :number_of_people
  end
end
