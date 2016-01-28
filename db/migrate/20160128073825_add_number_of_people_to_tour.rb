class AddNumberOfPeopleToTour < ActiveRecord::Migration
  def change
    add_column :tours, :number_of_people, :integer, null: false, default: 1
  end
end
