class AddPostalCodeToPartners < ActiveRecord::Migration[4.2]
  def change
    add_column :partners, :postal_code, :string, limit: 8
  end
end
