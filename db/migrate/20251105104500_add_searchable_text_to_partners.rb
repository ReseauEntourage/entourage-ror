class AddSearchableTextToPartners < ActiveRecord::Migration[7.1]
  def change
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
    enable_extension 'unaccent' unless extension_enabled?('unaccent')

    add_column :partners, :searchable_text, :text

    execute <<~SQL
      UPDATE partners
      SET searchable_text = unaccent(
        lower(
          coalesce(name, '')
        )
      );
    SQL

    add_index :partners,
      :searchable_text,
      name: :index_partners_on_searchable_text_trgm,
      using: :gin,
      opclass: :gin_trgm_ops
  end
end
