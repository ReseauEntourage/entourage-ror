class RemoveSmallLogoFromPartners < ActiveRecord::Migration[7.1]
  def change
    remove_column :partners, :small_logo_url
  end
end
