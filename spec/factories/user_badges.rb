FactoryBot.define do
  factory :user_badge do
    association :user
    badge_tag { "bienvenue" }
    active { true }
    awarded_at { Time.now }
  end
end
