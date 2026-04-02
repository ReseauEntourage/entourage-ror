FactoryBot.define do
  factory :engagement_level do
    user { association :public_user, community: community }

    level_1_count { 1 }
    level_2_count { 1 }
    level_3_count { 1 }

    initialize_with { new(attributes) }
  end
end
