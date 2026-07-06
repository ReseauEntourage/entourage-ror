FactoryBot.define do
  factory :user_badge do
    association :user, factory: :public_user
    badge_tag { 'bienvenue' }
    active { true }
    awarded_at { Time.now }
  end
end
