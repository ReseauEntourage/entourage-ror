FactoryGirl.define do
  factory :email_preference do
    association :user, factory: :public_user
    association :category, factory: :email_category
    subscribed true
  end
end
