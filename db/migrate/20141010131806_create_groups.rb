class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.belongs_to :street_person
      t.timestamps
    end
  end
end
