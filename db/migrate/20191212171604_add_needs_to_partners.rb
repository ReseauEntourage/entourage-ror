class AddNeedsToPartners < ActiveRecord::Migration[4.2]
  def change
    add_column :partners, :volunteers_needs, :text
    add_column :partners, :donations_needs, :text
  end
end
