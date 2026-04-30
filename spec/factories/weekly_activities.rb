FactoryBot.define do
  factory :weekly_activity do
    association :user
    week_iso { Time.now.strftime('%G-W%V') }
    has_group_action { true }
  end
end
