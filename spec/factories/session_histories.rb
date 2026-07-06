FactoryBot.define do
  factory :session_history do
    association :user, factory: :public_user
    date { Date.today }
    platform { 'ios' }
  end
end
