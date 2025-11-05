class AddSearchableTextToPartners < ActiveRecord::Migration[7.1]
  def change
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')

    add_column :partners, :searchable_text, :text
    add_index :partners,
      :searchable_text,
      name: :index_partners_on_searchable_text_trgm,
      using: :gin,
      opclass: :gin_trgm_ops
  end
end
