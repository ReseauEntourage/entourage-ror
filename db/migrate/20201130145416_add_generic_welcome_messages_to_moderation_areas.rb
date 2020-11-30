class AddGenericWelcomeMessagesToModerationAreas < ActiveRecord::Migration
  def change
    remove_column :moderation_areas, :welcome_message_1, :text
    remove_column :moderation_areas, :welcome_message_2, :text
    add_column :moderation_areas, :welcome_message_1_goal_not_known, :text
    add_column :moderation_areas, :welcome_message_2_goal_not_known, :text
  end
end
