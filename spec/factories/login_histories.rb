FactoryBot.define do
  factory :login_history do
    user { association :public_user }
  end
end
