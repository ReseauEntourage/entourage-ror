class RemoveInterlocutorsToModerationAreas < ActiveRecord::Migration[6.1]
  def change
    remove_column :moderation_areas, :moderator_id
    remove_column :moderation_areas, :mobilisator_id
    remove_column :moderation_areas, :accompanyist_id
  end
end
