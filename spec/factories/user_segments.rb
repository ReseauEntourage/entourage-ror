FactoryBot.define do
  factory :user_segment do
    association :user
    engagement_segment { nil }
    engagement_sub_segment { nil }
    segment_computed_at { Time.current }
  end
end
