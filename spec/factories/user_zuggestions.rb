FactoryBot.define do
  factory :user_zuggestion do
    association :user, factory: :public_user
    suggestion_type { 'connection' }
    reason { "parce que vous êtes dans le même quartier" }
    reason_type { 'zone' }
    expires_at { 7.days.from_now }

    trait :connection do
      suggestion_type { 'connection' }
      association :suggested_user, factory: :public_user
    end

    trait :next_step do
      suggestion_type { 'next_step' }
      suggested_action { 'join_event' }
    end

    trait :actioned do
      actioned_at { Time.current }
    end

    trait :dismissed do
      dismissed_at { Time.current }
      dismissed_until { 7.days.from_now }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end
  end
end
