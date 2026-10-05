class UserStat < ApplicationRecord
  # Denormalized impact counters exposed by V1::Users::SummarySerializer.
  #
  # Each counter is recomputed from the source tables, never incremented: a
  # counter left stale by a lost job is repaired by the next trigger for the
  # same user and counter. Triggers: UserImpactStatsObserver (actions) and
  # DenormChatMessageObserver (messages), through UserImpactStatsJob.

  COUNTED_ACTION_STATUSES = %w[open closed].freeze
  COUNTED_MESSAGE_STATUSES = %w[active updated].freeze
  UNCOUNTED_MESSAGE_TYPES = %w[broadcast auto status_update].freeze

  ACTION_CREATIONS = 'action_creations'.freeze
  NEIGHBORHOOD_MESSAGES = 'neighborhood_messages'.freeze
  CONVERSATION_MEMBERS = 'conversation_members'.freeze

  # Each query returns a single count for :user_id.
  COUNTER_QUERIES = {
    ACTION_CREATIONS => <<~SQL,
      SELECT COUNT(*) FROM entourages
      WHERE entourages.user_id = :user_id
        AND entourages.group_type = 'action'
        AND entourages.status IN (:action_statuses)
    SQL
    NEIGHBORHOOD_MESSAGES => <<~SQL,
      SELECT COUNT(*) FROM chat_messages
      WHERE chat_messages.user_id = :user_id
        AND chat_messages.messageable_type = 'Neighborhood'
        AND chat_messages.status IN (:message_statuses)
        AND chat_messages.message_type NOT IN (:uncounted_message_types)
    SQL
    # distinct other members of the conversations the user wrote in, whatever
    # their own membership status
    CONVERSATION_MEMBERS => <<~SQL
      SELECT COUNT(DISTINCT join_requests.user_id) FROM join_requests
      WHERE join_requests.joinable_type = 'Entourage'
        AND join_requests.user_id <> :user_id
        AND join_requests.joinable_id IN (
          SELECT chat_messages.messageable_id FROM chat_messages
          INNER JOIN entourages ON entourages.id = chat_messages.messageable_id
          WHERE chat_messages.user_id = :user_id
            AND chat_messages.messageable_type = 'Entourage'
            AND entourages.group_type = 'conversation'
            AND chat_messages.status IN (:message_statuses)
            AND chat_messages.message_type NOT IN (:uncounted_message_types)
        )
    SQL
  }.freeze

  COUNTERS = COUNTER_QUERIES.keys.freeze

  belongs_to :user

  class << self
    def counter? counter
      COUNTERS.include?(counter.to_s)
    end

    # Recomputes a single counter of a user in one atomic upsert, leaving the
    # other counters of the row untouched.
    def refresh! user_id, counter
      raise ArgumentError, "unknown counter: #{counter}" unless counter?(counter)

      column = connection.quote_column_name("#{counter}_count")

      connection.execute(sanitize_sql_array([<<~SQL, query_binds(user_id: user_id)]))
        INSERT INTO user_stats (user_id, #{column}, created_at, updated_at)
        VALUES (:user_id, (#{COUNTER_QUERIES[counter.to_s]}), NOW(), NOW())
        ON CONFLICT (user_id) DO UPDATE
          SET #{column} = EXCLUDED.#{column}, updated_at = EXCLUDED.updated_at
      SQL
    end

    # Recomputes every counter of the users whose id is in [from_id, to_id], in
    # one set-based statement. Users without any activity get no row, unless
    # they already have one, which is then reset.
    #
    # @see lib/tasks/user_stats.rake
    def backfill! from_id:, to_id:
      connection.exec_update(sanitize_sql_array([<<~SQL, query_binds(from_id: from_id, to_id: to_id)]))
        WITH action_creations AS (
          SELECT entourages.user_id, COUNT(*) AS value FROM entourages
          WHERE entourages.user_id BETWEEN :from_id AND :to_id
            AND entourages.group_type = 'action'
            AND entourages.status IN (:action_statuses)
          GROUP BY entourages.user_id
        ),
        neighborhood_messages AS (
          SELECT chat_messages.user_id, COUNT(*) AS value FROM chat_messages
          WHERE chat_messages.user_id BETWEEN :from_id AND :to_id
            AND chat_messages.messageable_type = 'Neighborhood'
            AND chat_messages.status IN (:message_statuses)
            AND chat_messages.message_type NOT IN (:uncounted_message_types)
          GROUP BY chat_messages.user_id
        ),
        written_conversations AS (
          SELECT DISTINCT chat_messages.user_id, chat_messages.messageable_id AS conversation_id
          FROM chat_messages
          INNER JOIN entourages ON entourages.id = chat_messages.messageable_id
          WHERE chat_messages.user_id BETWEEN :from_id AND :to_id
            AND chat_messages.messageable_type = 'Entourage'
            AND entourages.group_type = 'conversation'
            AND chat_messages.status IN (:message_statuses)
            AND chat_messages.message_type NOT IN (:uncounted_message_types)
        ),
        conversation_members AS (
          SELECT written_conversations.user_id, COUNT(DISTINCT join_requests.user_id) AS value
          FROM written_conversations
          INNER JOIN join_requests
            ON join_requests.joinable_type = 'Entourage'
            AND join_requests.joinable_id = written_conversations.conversation_id
            AND join_requests.user_id <> written_conversations.user_id
          GROUP BY written_conversations.user_id
        ),
        user_ids AS (
          SELECT user_id FROM action_creations
          UNION SELECT user_id FROM neighborhood_messages
          UNION SELECT user_id FROM conversation_members
          UNION SELECT user_id FROM user_stats WHERE user_id BETWEEN :from_id AND :to_id
        )
        INSERT INTO user_stats (user_id, action_creations_count, neighborhood_messages_count, conversation_members_count, created_at, updated_at)
        SELECT
          user_ids.user_id,
          COALESCE(action_creations.value, 0),
          COALESCE(neighborhood_messages.value, 0),
          COALESCE(conversation_members.value, 0),
          NOW(),
          NOW()
        FROM user_ids
        LEFT JOIN action_creations ON action_creations.user_id = user_ids.user_id
        LEFT JOIN neighborhood_messages ON neighborhood_messages.user_id = user_ids.user_id
        LEFT JOIN conversation_members ON conversation_members.user_id = user_ids.user_id
        ON CONFLICT (user_id) DO UPDATE SET
          action_creations_count = EXCLUDED.action_creations_count,
          neighborhood_messages_count = EXCLUDED.neighborhood_messages_count,
          conversation_members_count = EXCLUDED.conversation_members_count,
          updated_at = EXCLUDED.updated_at
      SQL
    end

    private

    def query_binds values
      values.merge(
        action_statuses: COUNTED_ACTION_STATUSES,
        message_statuses: COUNTED_MESSAGE_STATUSES,
        uncounted_message_types: UNCOUNTED_MESSAGE_TYPES
      )
    end
  end
end
