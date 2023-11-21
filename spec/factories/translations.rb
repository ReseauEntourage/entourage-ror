FactoryBot.define do
  factory :translation do
    association :instance, factory: :chat_message
  end
end
