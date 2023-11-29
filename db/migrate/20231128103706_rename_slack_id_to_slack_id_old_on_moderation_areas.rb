class RenameSlackIdToSlackIdOldOnModerationAreas < ActiveRecord::Migration[6.1]
  def change
    rename_column :moderation_areas, :slack_moderator_id, :slack_moderator_id_old
  end
end
