FactoryGirl.define do
  factory :chat_message do
    association :messageable, factory: :tour
    content "MyText"
    association :user, factory: :pro_user
  end

  trait :closed_as_success do
    message_type :status_update
    metadata status: :closed,
             outcome_success: true
  end
end
