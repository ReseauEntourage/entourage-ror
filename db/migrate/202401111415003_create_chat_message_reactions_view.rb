class CreateChatMessageReactionsView < ActiveRecord::Migration[6.1]
  def up
    sql = <<-SQL
      CREATE VIEW chat_message_reactions AS
        SELECT
          chat_messages.id AS "chat_message_id",
          user_reactions.reaction_id AS "reaction_id",
          count(*) as reactions_count

        FROM user_reactions

        LEFT JOIN chat_messages
          on user_reactions.instance_id = chat_messages.id
          and user_reactions.instance_type = 'ChatMessage'

        LEFT JOIN neighborhoods
          on chat_messages.messageable_type = 'Neighborhood'
          and chat_messages.messageable_id = neighborhoods.id

        LEFT JOIN entourages
          on chat_messages.messageable_type = 'Entourage'
          and chat_messages.messageable_id = entourages.id
          and entourages.group_type = 'outing'

        WHERE chat_messages.created_at > '2024-01-01' -- reactions start in 2024
          and chat_messages.ancestry is null -- reactions apply to posts only

        GROUP BY
          chat_messages.id,
          user_reactions.reaction_id
    SQL

    execute(sql)
  end

  def down
    execute('DROP VIEW chat_message_reactions')
  end
end
