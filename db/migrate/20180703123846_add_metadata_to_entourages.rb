class AddMetadataToEntourages < ActiveRecord::Migration
  def change
    add_column :entourages, :metadata, :jsonb, default: {}, null: false
  end
end
