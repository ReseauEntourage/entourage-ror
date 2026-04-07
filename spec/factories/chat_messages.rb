FactoryBot.define do
  factory :chat_message do
    association :messageable, factory: :entourage
    association :user, factory: :pro_user
    content { 'MyText' }

    trait :private do
      association :messageable, factory: :conversation
    end

    factory :private_chat_message, traits: [:private]
  end

  trait :closed_as_success do
    message_type { :status_update }
    metadata { { status: :closed, outcome_success: true } }
  end

  trait :neighborhood_post do
    messageable { association :neighborhood }
    user { association :public_user }
    content { 'MyText' }
  end
end
