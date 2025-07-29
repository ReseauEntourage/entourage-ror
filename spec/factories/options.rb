FactoryBot.define do
  factory :option do
    key { 'key' }
    active { true }

    trait :soliguide do
      key { :soliguide }
    end

    factory :option_soliguide, traits: [:soliguide]
  end
end
