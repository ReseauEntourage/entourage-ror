class AddUsersCountToConversationMessageBroadcasts < ActiveRecord::Migration[4.2]
  def up
    add_column :conversation_message_broadcasts, :sent_users_count, :integer

    reversible do |dir|
      dir.up do
        unless EnvironmentHelper.test?
          ConversationMessageBroadcast.find_in_batches(batch_size: 10) do |broadcasts|
            broadcasts.each do |broadcast|
              count = broadcast.sent_count

              broadcast.update_attribute(:sent_users_count, count) unless broadcast.sent_users_count
            end
          end
        end
      end
    end
  end

  def down
    remove_column :conversation_message_broadcasts, :sent_users_count
  end
end
