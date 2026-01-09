class RenameLargeLogoToImageUrlOnPartners < ActiveRecord::Migration[7.1]
  def up
    add_column :partners, :image_url, :string

    execute <<~SQL
      UPDATE partners
      SET image_url = large_logo_url
    SQL

    execute <<~SQL
      UPDATE partners
      SET image_url = SUBSTRING(image_url FROM #{prefix.length + 1})
      WHERE image_url LIKE '#{prefix}%';
    SQL

    rename_column :partners, :large_logo_url, :large_logo_url_old
  end

  def down
    remove_column :partners, :image_url, :string
    rename_column :partners, :large_logo_url_old, :large_logo_url
  end

  private

  def prefix
    @prefix ||= Partner.bucket.public_url(key: Partner.bucket_prefix + "/")
  end
end
