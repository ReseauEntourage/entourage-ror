# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :tour do
    tour_type "medical"
    vehicle_type "feet"
    status "ongoing"
    number_of_people 1
    user
    
    trait :filled do
      transient do
        point_count 10
        encounter_count 2
      end
      status 'closed'
      length 123
      created_at { Time.now - 3 * 60 * 60 }
      closed_at { Time.now - 2 * 60 * 60 }
      after(:create) do |tour, evaluator|
        create_list(:tour_point, 2, :in_paris, :now, tour: tour)
        create_list(:encounter, 2, :in_paris, :now, tour: tour)
      end
    end
  end
end
