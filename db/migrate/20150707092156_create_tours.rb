class CreateTours < ActiveRecord::Migration[4.2]
  def change
    create_table :tours do |t|
      t.string :tour_type

      t.timestamps
    end
  end
end
