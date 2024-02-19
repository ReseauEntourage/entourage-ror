class Survey < ApplicationRecord
  # attr questions (jsonb)
  # attr multiple (boolean)

  has_one :chat_message
end
