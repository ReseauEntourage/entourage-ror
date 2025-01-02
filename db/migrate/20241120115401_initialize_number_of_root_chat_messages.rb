class InitializeNumberOfRootChatMessages < ActiveRecord::Migration[6.1]
  def up
    # entourages
    execute <<-SQL.squish
      UPDATE entourages
      SET number_of_root_chat_messages = (
        SELECT COUNT(*)
        FROM chat_messages
        WHERE chat_messages.messageable_id = entourages.id
          AND chat_messages.messageable_type = 'Entourage'
          AND chat_messages.ancestry IS NULL
          AND chat_messages.status != 'deleted'
      )
    SQL

    # neighborhoods
    execute <<-SQL.squish
      UPDATE neighborhoods
      SET number_of_root_chat_messages = (
        SELECT COUNT(*)
        FROM chat_messages
        WHERE chat_messages.messageable_id = neighborhoods.id
          AND chat_messages.messageable_type = 'Neighborhood'
          AND chat_messages.ancestry IS NULL
          AND chat_messages.status != 'deleted'
      )
    SQL
  end

  def down
    Entourage.update_all(number_of_root_chat_messages: nil)
    Neighborhood.update_all(number_of_root_chat_messages: nil)
  end
end
