class AddNumberOfPeopleToTour < ActiveRecord::Migration[4.2]
  def change
    add_column :tours, :number_of_people, :integer, null: false, default: 1
  end
end
