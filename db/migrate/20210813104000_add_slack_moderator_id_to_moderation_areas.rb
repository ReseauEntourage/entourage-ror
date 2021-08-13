class AddSlackModeratorIdToModerationAreas < ActiveRecord::Migration[5.1]
  def up
    add_column :moderation_areas, :slack_moderator_id, :string, default: nil, length: 11
  end

  def down
    remove_column :moderation_areas, :slack_moderator_id
  end
end
