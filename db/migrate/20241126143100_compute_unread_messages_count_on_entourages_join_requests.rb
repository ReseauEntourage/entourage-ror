class ComputeUnreadMessagesCountOnEntouragesJoinRequests < ActiveRecord::Migration[6.1]
  def up
    unless Rails.env.test?
      sql = <<-SQL
        WITH filtered_chat_messages AS (
          SELECT
            messageable_type,
            messageable_id,
            created_at
          FROM chat_messages
          WHERE ancestry IS NULL
            AND status IN ('active', 'updated')
        ), filtered_join_requests AS (
          SELECT
            user_id,
            joinable_type,
            joinable_id,
            last_message_read
          FROM join_requests
          WHERE status = 'accepted'
        ), unread_counts AS (
          SELECT
            fjr.user_id,
            fjr.joinable_type AS messageable_type,
            fjr.joinable_id AS messageable_id,
            COUNT(fcm.created_at) AS unread_messages_count
          FROM filtered_join_requests fjr
          LEFT JOIN filtered_chat_messages fcm
          ON fjr.joinable_type = fcm.messageable_type
            AND fjr.joinable_id = fcm.messageable_id
            AND (fcm.created_at > fjr.last_message_read OR fjr.last_message_read IS NULL)
          GROUP BY fjr.user_id, fjr.joinable_type, fjr.joinable_id, fjr.last_message_read
        )
        UPDATE join_requests
        SET unread_messages_count = unread_counts.unread_messages_count
        FROM unread_counts
        WHERE join_requests.user_id = unread_counts.user_id
          AND join_requests.joinable_type = unread_counts.messageable_type
          AND join_requests.joinable_id = unread_counts.messageable_id;
      SQL

      ActiveRecord::Base.connection.execute(sql)
    end
  end

  def down
    JoinRequest.where(joinable_type: :Entourage).update_all(unread_messages_count: nil)
  end
end
