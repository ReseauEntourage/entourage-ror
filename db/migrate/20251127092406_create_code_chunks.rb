class CreateCodeChunks < ActiveRecord::Migration[7.1]
  def change
    enable_extension "vector" unless Rails.env.test?

    create_table :code_chunks do |t|
      t.string  :filepath, null: false
      t.integer :start_line, null: false
      t.integer :end_line, null: false
      t.text    :content, null: false

      if Rails.env.test?
        t.text :embedding
      else
        t.column :embedding, "vector(1536)"
      end

      t.timestamps
    end

    unless Rails.env.test?
      execute <<~SQL
        CREATE INDEX code_chunks_embedding_ivfflat
        ON code_chunks
        USING ivfflat (embedding vector_l2_ops)
        WITH (lists = 100);
      SQL
    end
  end
end
