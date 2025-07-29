FactoryBot.define do
  factory :address do
    place_name { 'rue Pizza' }
    latitude { 1.5 }
    longitude { 1.5 }
    postal_code { '75020' }
    country { 'FR' }
    user { association :public_user }

    trait :blank do
      place_name { nil }
      latitude { nil }
      longitude { nil }
      postal_code { nil }
      country { nil }
      user { nil }
    end
  end
end
