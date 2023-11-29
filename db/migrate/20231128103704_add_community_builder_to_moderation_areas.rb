class AddCommunityBuilderToModerationAreas < ActiveRecord::Migration[6.1]
  def change
    add_column :moderation_areas, :community_builder_id, :integer, null: true
  end
end
