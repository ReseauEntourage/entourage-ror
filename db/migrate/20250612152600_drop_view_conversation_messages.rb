class DropViewConversationMessages < ActiveRecord::Migration[6.1]
  def up
    execute 'DROP VIEW IF EXISTS conversation_messages;'
  end

  def down
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
end
