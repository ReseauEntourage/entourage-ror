FactoryBot.define do
  factory :user_blocked_user do
    user { association :public_user }
    blocked_user { association :public_user }
  end
end
