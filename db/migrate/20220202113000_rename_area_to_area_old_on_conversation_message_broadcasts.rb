class RenameAreaToAreaOldOnConversationMessageBroadcasts < ActiveRecord::Migration[5.2]
  def up
    change_column_null :conversation_message_broadcasts, :area, true
    rename_column :conversation_message_broadcasts, :area, :area_old

  end

  def down
    rename_column :conversation_message_broadcasts, :area_old, :area
    change_column_null :conversation_message_broadcasts, :area, false
  end
end
