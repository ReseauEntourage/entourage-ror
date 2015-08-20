# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :tour_point do
    latitude 1.5
    longitude 1.5
    tour
    passing_time "2015-07-07 12:31:43"
    
    trait :in_paris do
      latitude { rand * (48.88 - 48.83) + 48.83 } # between 48.83 and 48.88
      longitude { rand * (2.39 - 2.29) + 2.29 } # between 2.29 and 2.39
    end
    trait :now do
      passing_time now
    end
  end
end
