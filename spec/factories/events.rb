FactoryBot.define do
  factory :event do
    name { 'onboarding.resource.welcome_watched' }
    user { association :public_user }
  end
end
