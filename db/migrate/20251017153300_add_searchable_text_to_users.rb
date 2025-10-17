class AddSearchableTextToUsers < ActiveRecord::Migration[7.1]
  def change
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')

    add_column :users, :searchable_text, :text,
      as: "lower(
             coalesce(last_name, '') || ' ' ||
             coalesce(first_name, '') || ' ' ||
             coalesce(phone, '') || ' ' ||
             coalesce(email, '')
           )",
      stored: true

    add_index :users,
      :searchable_text,
      name: :index_users_on_searchable_text_trgm,
      using: :gin,
      opclass: :gin_trgm_ops
  end
end
