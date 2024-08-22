class TwoVectorsColumnsToLexicalTransformations < ActiveRecord::Migration[6.1]
  def change
    remove_index :lexical_transformations, :vectors

    rename_column :lexical_transformations, :vectors, :vectors_minilm_l6
    add_column :lexical_transformations, :vectors_minilm_l12, :jsonb

    add_index :lexical_transformations, :vectors_minilm_l6, using: :gin
    add_index :lexical_transformations, :vectors_minilm_l12, using: :gin
  end
end
