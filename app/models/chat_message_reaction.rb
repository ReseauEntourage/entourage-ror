class ChatMessageReaction < ApplicationRecord
  belongs_to :chat_message
  belongs_to :reaction
end
