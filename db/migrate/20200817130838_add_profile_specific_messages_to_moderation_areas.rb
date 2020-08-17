class AddProfileSpecificMessagesToModerationAreas < ActiveRecord::Migration
  def change
    change_table :moderation_areas do |t|
      t.text :welcome_message_1_offer_help
      t.text :welcome_message_2_offer_help
      t.text :welcome_message_1_ask_for_help
      t.text :welcome_message_2_ask_for_help
      t.text :welcome_message_1_organization
      t.text :welcome_message_2_organization
    end

    reversible do |dir|
      dir.up do
        ModerationArea.reset_column_information
        ModerationArea.find_each do |area|
          area.welcome_message_1_offer_help   = area.welcome_message_1
          area.welcome_message_1_ask_for_help = area.welcome_message_1
          area.welcome_message_1_organization = area.welcome_message_1

          area.welcome_message_2_offer_help   = area.welcome_message_2
          area.welcome_message_2_ask_for_help = area.welcome_message_2
          area.welcome_message_2_organization = area.welcome_message_2

          area.save
        end
      end
    end unless Rails.env.test?
  end
end
