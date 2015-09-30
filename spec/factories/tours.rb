# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :tour do
    tour_type "social"
    vehicle_type "feet"
    status "ongoing"
    user
    
    trait :filled do
      transient do
        point_count 10
      end
      status 'closed'
      length { rand * 2000 + 400 }
      created_at { Time.now - 3 * 60 * 60 }
      closed_at { Time.now - 2 * 60 * 60 }
      after(:create) do |tour, evaluator|
        create_list(:tour_point, evaluator.point_count, :in_paris, :now, tour: tour)
        create_list(:encounter, 2, :in_paris, :now, tour: tour)
      end
    end
  end
end
