class CreateLastChatMessagesView < ActiveRecord::Migration[4.2]
  def up
    sql = <<-SQL
      drop view if exists last_chat_messages;
      create view last_chat_messages as
        select distinct on (messageable_id)
          id,
          created_at,
          messageable_id as entourage_id
        from chat_messages
        where messageable_type = 'Entourage'
        order by messageable_id, created_at desc
    SQL

    execute(sql)
  end

  def down
    sql = <<-SQL
      DROP VIEW IF EXISTS last_chat_messages
    SQL

    execute(sql)
  end
end
