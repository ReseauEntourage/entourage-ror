FactoryBot.define do
  factory :denorm_daily_engagement do
    association :user, factory: :user
    date { Time.now }
  end
end
