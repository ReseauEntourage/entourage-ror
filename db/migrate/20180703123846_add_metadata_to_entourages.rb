class AddMetadataToEntourages < ActiveRecord::Migration[4.2]
  def change
    add_column :entourages, :metadata, :jsonb, default: {}, null: false
  end
end
