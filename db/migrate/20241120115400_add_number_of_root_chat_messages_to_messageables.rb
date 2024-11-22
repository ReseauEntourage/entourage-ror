class AddNumberOfRootChatMessagesToMessageables < ActiveRecord::Migration[6.1]
  def change
    add_column :entourages, :number_of_root_chat_messages, :integer, default: 0
    add_column :neighborhoods, :number_of_root_chat_messages, :integer, default: 0
  end
end
