class UnreadChatMessageJob
  include Sidekiq::Worker

  sidekiq_options :retry => true, queue: :default

  def perform messageable_type, messageable_id
    return unless record = messageable_type.constantize.unscoped.find_by(id: messageable_id)
    return unless record.is_a?(Neighborhood)

    compute_unread_on_neighborhood(record.id)
  end

  def compute_unread_on_neighborhood neighborhood_id
    sql = <<-SQL
      WITH filtered_chat_messages AS (
        SELECT created_at
        FROM chat_messages
        WHERE messageable_id = :neighborhood_id AND messageable_type = 'Neighborhood'
          AND ancestry IS NULL
          AND status IN ('active', 'updated')
      ), filtered_join_requests AS (
        SELECT
          user_id,
          last_message_read
        FROM join_requests
        WHERE joinable_id = :neighborhood_id AND joinable_type = 'Neighborhood'
          AND status = 'accepted'
      ), unread_counts AS (
        SELECT
          fjr.user_id,
          fjr.last_message_read,
          COUNT(fcm.created_at) AS unread_messages_count
        FROM filtered_join_requests fjr
        LEFT JOIN filtered_chat_messages fcm
        ON fcm.created_at > fjr.last_message_read OR fjr.last_message_read IS NULL
        GROUP BY fjr.user_id, fjr.last_message_read
        ORDER BY unread_messages_count DESC
      )
      UPDATE join_requests
      SET unread_messages_count = unread_counts.unread_messages_count
      FROM unread_counts
      WHERE join_requests.user_id = unread_counts.user_id
      AND join_requests.joinable_id = :neighborhood_id
      AND join_requests.joinable_type = 'Neighborhood';
    SQL

    ActiveRecord::Base.connection.execute(ActiveRecord::Base.send(:sanitize_sql_array, [sql, { neighborhood_id: neighborhood_id }]))

  end

  def self.perform_later messageable_type, messageable_id
    UnreadChatMessageJob.perform_async(messageable_type, messageable_id)
  end
end
