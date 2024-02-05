FactoryBot.define do
  factory :user_reaction do
    association :user, factory: :public_user
    association :reaction, factory: :reaction
    association :instance, factory: :chat_message
  end
end
