FactoryBot.define do
  factory :survey_response do
    user { association :public_user }
    chat_message { association :chat_message }
  end
end
