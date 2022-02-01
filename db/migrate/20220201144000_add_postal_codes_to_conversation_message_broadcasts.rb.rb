class AddPostalCodesToConversationMessageBroadcasts < ActiveRecord::Migration[5.2]
  def up
    # area_type
    add_column :conversation_message_broadcasts, :area_type, :string
    add_index  :conversation_message_broadcasts, :area_type

    # areas
    add_column :conversation_message_broadcasts, :areas, :jsonb, default: [], null: false

    # data migration
    execute <<-SQL
      update conversation_message_broadcasts set area_type = area where area in ('national', 'sans_zone', 'hors_zone');
      update conversation_message_broadcasts set area_type = 'list' where area not in ('national', 'sans_zone', 'hors_zone');
      update conversation_message_broadcasts set areas = to_jsonb(string_to_array(right(area, 2), ',')) where area like 'dep_%';
    SQL
  end

  def down
    # area_type
    remove_index  :conversation_message_broadcasts, :area_type
    remove_column :conversation_message_broadcasts, :area_type

    # area_type
    remove_column :conversation_message_broadcasts, :areas
  end
end
