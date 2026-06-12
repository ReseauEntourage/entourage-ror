FactoryBot.define do
  factory :login_history do
    user { association :public_user }
    connected_at { Time.current }
  end
end
