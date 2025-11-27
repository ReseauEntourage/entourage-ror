class CreateCodeChunks < ActiveRecord::Migration[7.1]
  def change
    enable_extension "vector" unless extension_enabled?("vector")

    create_table :code_chunks do |t|
      t.string  :filepath, null: false
      t.integer :start_line, null: false
      t.integer :end_line, null: false
      t.text    :content, null: false

      t.column :embedding, "vector(1536)"

      t.timestamps
    end

    execute <<~SQL
      CREATE INDEX code_chunks_embedding_ivfflat
      ON code_chunks
      USING ivfflat (embedding vector_l2_ops)
      WITH (lists = 100);
    SQL
  end
end
