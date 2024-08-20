class RenameNameToVectorsOnLexicalTransformations < ActiveRecord::Migration[6.1]
  def change
    remove_index :lexical_transformations, :name
    remove_index :lexical_transformations, :description

    rename_column :lexical_transformations, :name, :vectors
    remove_column :lexical_transformations, :description

    add_index :lexical_transformations, :vectors, using: :gin
  end
end
