class AddSearchableTextToUsers < ActiveRecord::Migration[7.1]
  def change
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
    enable_extension 'unaccent' unless extension_enabled?('unaccent')

    add_column :users, :searchable_text, :text

    # execute <<~SQL
    #   UPDATE users
    #   SET searchable_text = unaccent(
    #     lower(
    #       coalesce(first_name, '') || ' ' ||
    #       coalesce(last_name, '') || ' ' ||
    #       coalesce(phone, '') || ' ' ||
    #       coalesce(email, '')
    #     )
    #   );
    # SQL

    add_index :users,
      :searchable_text,
      name: :index_users_on_searchable_text_trgm,
      using: :gin,
      opclass: :gin_trgm_ops
  end
end
