# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :tour do
    transient do
      join_request_user nil
    end

    tour_type "medical"
    vehicle_type "feet"
    status "ongoing"
    number_of_people 1
    association :user, factory: :pro_user
    
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
        create(:tour_point, :now, latitude: "49.40752907", longitude: "0.26782405", tour: tour)
        create(:tour_point, :now, latitude: "49.40774009", longitude: "0.26870057", tour: tour)
        create_list(:encounter, 2, :in_paris, :now, tour: tour)
      end
    end

    trait :joined do
      after(:create) do |tour, evaluator|
        role = evaluator.join_request_user == tour.user ? :creator : :member
        evaluator.join_request_user.join_requests.create!(joinable: tour, role: role, status: JoinRequest::ACCEPTED_STATUS)
      end
    end
  end
end
