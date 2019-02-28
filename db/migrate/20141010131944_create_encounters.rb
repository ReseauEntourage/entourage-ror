class CreateEncounters < ActiveRecord::Migration
  def change
    create_table :encounters do |t|
      t.datetime :date
      t.string :location
      t.belongs_to :user
      t.belongs_to :group

      t.timestamps
    end
  end
end
