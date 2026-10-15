# One embedding per record (action, outing, neighborhood, poi, resource) used by the hybrid matching.
# Vectors are stored as real[] rather than pgvector: the extension is not available on every database we run (CI, local).
# Similarities are computed on candidates already filtered in SQL, so no vector index is needed.
class CreateEmbeddings < ActiveRecord::Migration[7.1]
  def change
    create_table :embeddings do |t|
      t.string :embeddable_type, null: false
      t.integer :embeddable_id, null: false
      t.string :model, null: false
      t.string :digest, null: false
      t.column :vector, 'real[]', null: false

      t.timestamps
    end

    add_index :embeddings, [:embeddable_type, :embeddable_id], unique: true
  end
end
