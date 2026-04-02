FactoryBot.define do
  factory :denorm_daily_engagements_with_type do
    date { Date.current }
    association :user, factory: :user
    postal_code { '75001' }
    engagement_type { 'reaction' }
  end
end
