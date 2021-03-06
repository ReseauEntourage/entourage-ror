class AddDescriptionToPartners < ActiveRecord::Migration[4.2]
  def change
    add_column :partners, :description, :text
    add_column :partners, :phone, :string
    add_column :partners, :address, :string
    add_column :partners, :website_url, :string
    add_column :partners, :email, :string
  end
end
