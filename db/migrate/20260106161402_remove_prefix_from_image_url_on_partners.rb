class RemovePrefixFromImageUrlOnPartners < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      UPDATE partners
      SET image_url = SUBSTRING(image_url FROM #{prefix.length + 1})
      WHERE image_url LIKE '#{prefix}%';
    SQL
  end

  def down
    execute <<~SQL
      UPDATE partners
      SET image_url = '#{prefix}' || image_url
      WHERE image_url IS NOT NULL
        AND image_url NOT LIKE '#{prefix}%';
    SQL
  end

  private

  def prefix
    @prefix ||= Partner.bucket.public_url(key: Partner.bucket_prefix + "/")
  end
end
