class AddModeratorsToModerationAreas < ActiveRecord::Migration[6.1]
  def change
    add_column :moderation_areas, :animator_id, :integer, null: true
    add_column :moderation_areas, :mobilisator_id, :integer, null: true
    add_column :moderation_areas, :sourcing_id, :integer, null: true
    add_column :moderation_areas, :accompanyist_id, :integer, null: true
  end
end
