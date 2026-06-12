FactoryBot.define do
  factory :user_next_step do
    association :user
    association :next_step_suggestion
    status { 'active' }
    shown_at { Time.zone.now }
    expires_at { 3.days.from_now }
  end
end
