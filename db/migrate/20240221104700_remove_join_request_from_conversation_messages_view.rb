class RemoveJoinRequestFromConversationMessagesView < ActiveRecord::Migration[6.1]
  def up
    execute 'DROP VIEW IF EXISTS conversation_messages;'

    sql = <<-SQL
      create or replace view conversation_messages as
        select
          messageable_type,
          messageable_id,
          content,
          status,
          user_id,
          created_at,
          updated_at,
          'ChatMessage' as full_object_type,
          id as full_object_id,
          ancestry,
          image_url
        from chat_messages
    SQL

    execute(sql)
  end

  def down
    execute 'DROP VIEW IF EXISTS conversation_messages;'

    sql = <<-SQL
      create or replace view conversation_messages as
        select
          messageable_type,
          messageable_id,
          content,
          status,
          user_id,
          created_at,
          updated_at,
          'ChatMessage' as full_object_type,
          id as full_object_id,
          ancestry,
          image_url
        from chat_messages

        union all

        select
          joinable_type as messageable_type,
          joinable_id as messageable_id,
          message as content,
          status,
          user_id,
          created_at,
          updated_at,
          'JoinRequest' as full_object_type,
          id as full_object_id,
          null as ancestry,
          null as image_url
        from join_requests
        where status in ('pending', 'accepted')
          and message <> ''
    SQL

    execute(sql)
  end
end
