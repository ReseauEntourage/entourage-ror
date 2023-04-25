FactoryBot.define do
  factory :entourage_moderation do
    entourage { association :contribution, status: :closed }
    action_outcome { 'Oui' }

    trait :oui do
      action_outcome { 'Oui' }
    end

    trait :non do
      action_outcome { 'Non' }
    end

    trait :validated do
      validated_at { Time.now }
      moderated_at { Time.now }
    end

    trait :moderated do
      moderated_at { Time.now }
    end
  end
end
