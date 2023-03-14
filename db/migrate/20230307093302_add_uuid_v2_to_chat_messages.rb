class AddUuidV2ToChatMessages < ActiveRecord::Migration[5.2]
  def up
    add_column :chat_messages, :uuid_v2, :string, limit: 12

    execute <<-SQL
      update chat_messages set uuid_v2 = left(MD5(random()::text), 12);
    SQL

    change_column :chat_messages, :uuid_v2, :string, limit: 12, null: false

    # add_index :chat_messages, :uuid_v2, unique: true
  end

  def down
    # remove_index :chat_messages, :uuid_v2

    remove_column :chat_messages, :uuid_v2
  end
end
