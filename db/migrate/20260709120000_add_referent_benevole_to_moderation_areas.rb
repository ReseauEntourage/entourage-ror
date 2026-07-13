class AddReferentBenevoleToModerationAreas < ActiveRecord::Migration[7.1]
  def change
    add_column :moderation_areas, :referent_benevole_id, :integer, null: true
  end
end
