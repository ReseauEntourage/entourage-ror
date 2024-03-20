class AddNumberOfConfirmedPeopleToEntourages < ActiveRecord::Migration[6.1]
  def up
    add_column :entourages, :number_of_confirmed_people, :integer, default: 0
  end

  def down
    remove_column :entourages, :number_of_confirmed_people
  end
end
