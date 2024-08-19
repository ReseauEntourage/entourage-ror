class CreateLexicalTransformations < ActiveRecord::Migration[6.1]
  def change
    create_table :lexical_transformations do |t|
      t.string :instance_type, nullable: false
      t.integer :instance_id, nullable: false
      t.jsonb :name
      t.jsonb :description

      t.timestamps null: false
    end

    add_index :lexical_transformations, [:instance_type, :instance_id], unique: true
    add_index :lexical_transformations, :name, using: :gin
    add_index :lexical_transformations, :description, using: :gin
  end
end

