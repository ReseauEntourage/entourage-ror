# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :tour_point do
    latitude { 1.5 }
    longitude { 1.5 }
    tour
    passing_time { "2015-07-07 12:31:43" }

    trait :in_paris do
      latitude { 48.83 }
      longitude { 2.29 }
    end
    trait :now do
      passing_time { Time.now }
    end
  end
end
