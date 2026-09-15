FactoryBot.define do
  factory :user_segment_history do
    association :user
    engagement_segment { 'Curieux' }
    engagement_sub_segment { nil }
    valid_from { Date.current }
    valid_to { nil }
    computed_at { Time.current }
  end
end
