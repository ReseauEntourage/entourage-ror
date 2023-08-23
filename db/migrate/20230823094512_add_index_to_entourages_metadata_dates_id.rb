class AddIndexToEntouragesMetadataDatesId < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      CREATE INDEX IF NOT EXISTS index_entourages_metadata_dates ON entourages ((metadata->>'ends_at'), (metadata->>'starts_at'));
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX if exists index_entourages_metadata_dates;
    SQL
  end
end
