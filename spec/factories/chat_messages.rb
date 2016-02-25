FactoryGirl.define do
  factory :chat_message do
    association :messageable, factory: :tour
    content "MyText"
    association :user, factory: :pro_user
  end

end
