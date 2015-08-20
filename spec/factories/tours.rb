# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :tour do
    tour_type "social"
    vehicle_type "feet"
    status "ongoing"
    user
    
    trait :filled do
      after(:create) do |tour, evaluator|
        create_list(:tour_point, 10, :in_paris, tour: tour)
      end
    end
  end
end
