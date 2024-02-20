class SurveyResponse < ApplicationRecord
  belongs_to :user
  belongs_to :chat_message

  validates_uniqueness_of :user_id, scope: [:chat_message_id], message: "You can only answer once"
end
