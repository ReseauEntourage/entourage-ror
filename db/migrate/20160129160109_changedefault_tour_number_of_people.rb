class ChangedefaultTourNumberOfPeople < ActiveRecord::Migration
  def change
    change_column :tours, :number_of_people, :integer, null: false, default: 0
    change_column :entourages, :number_of_people, :integer, null: false, default: 0
  end
end
