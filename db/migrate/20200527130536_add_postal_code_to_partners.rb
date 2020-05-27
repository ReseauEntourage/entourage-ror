class AddPostalCodeToPartners < ActiveRecord::Migration
  def change
    add_column :partners, :postal_code, :string, limit: 8
  end
end
