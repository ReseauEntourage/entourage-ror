class AddGinIndexToChatMessages < ActiveRecord::Migration[5.2]
  def up
    enable_extension :pg_trgm
    add_index :chat_messages, :content, opclass: :gin_trgm_ops, using: :gin
  end

  def down
    remove_index :chat_messages, :content
    disable_extension :pg_trgm
  end
end
