class CreateNeighborhoodsEntourages < ActiveRecord::Migration[5.2]
  def up
    create_table :neighborhoods_entourages do |t|
      t.belongs_to :neighborhood, index: true
      t.belongs_to :entourage, index: true
      t.timestamps
    end
  end

  def down
    drop_table :neighborhoods_entourages
  end
end

