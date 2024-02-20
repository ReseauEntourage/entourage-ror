module V1
  class SurveyResponseSerializer < ActiveModel::Serializer
    attributes :user_id,
               :chat_message_id,
               :responses
  end
end
