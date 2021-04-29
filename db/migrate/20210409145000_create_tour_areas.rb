class CreateTourAreas < ActiveRecord::Migration
  def up
    create_table :tour_areas do |t|
      t.string :departement, limit: 5
      t.string :area, null: false
      t.string :status, null: false, default: :inactive
      t.string :email, null: false

      t.timestamps null: false

      t.index :area
      t.index :status
    end
  end

  def down
    drop_table :tour_areas
  end
end

