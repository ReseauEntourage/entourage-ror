class RemoveCommunityBuilderFromModerationAreas < ActiveRecord::Migration[7.1]
  def change
    remove_column :moderation_areas, :community_builder_id, :integer
  end
end
