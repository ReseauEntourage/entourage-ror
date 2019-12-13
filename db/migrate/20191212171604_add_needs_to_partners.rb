class AddNeedsToPartners < ActiveRecord::Migration
  def change
    add_column :partners, :volunteers_needs, :text
    add_column :partners, :donations_needs, :text
  end
end
