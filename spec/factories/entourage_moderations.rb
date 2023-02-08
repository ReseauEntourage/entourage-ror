FactoryBot.define do
  factory :entourage_moderation do
    entourage { association :contribution, status: :closed }
    action_outcome { 'Oui' }

    trait :oui do action_outcome { 'Oui' } end
    trait :non do action_outcome { 'Non' } end
  end
end
