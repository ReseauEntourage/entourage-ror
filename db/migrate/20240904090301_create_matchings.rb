class CreateMatchings < ActiveRecord::Migration[6.1]
  def change
    create_table :matchings do |t|
      t.string :instance_type, null: false
      t.integer :instance_id, null: false

      t.string :match_type, null: false
      t.integer :match_id, null: false

      t.float :score
      t.integer :position

      t.timestamps null: false

      t.index [:instance_type, :instance_id]
    end
  end
end
