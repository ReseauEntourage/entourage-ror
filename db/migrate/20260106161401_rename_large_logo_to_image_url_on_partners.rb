class RenameLargeLogoToImageUrlOnPartners < ActiveRecord::Migration[7.1]
  def change
    rename_column :partners, :large_logo_url, :image_url
  end
end
