FactoryGirl.define do
  factory :entourage do
    transient do
      join_request_user nil
    end

    status "open"
    title "foobar"
    entourage_type "ask_for_help"
    association :user, factory: :public_user
    latitude 1.122
    longitude 2.345
    number_of_people 1

    trait :joined do
      after(:create) do |entourage, evaluator|
        FactoryGirl.create(:join_request, joinable: entourage, user: evaluator.join_request_user, status: JoinRequest::ACCEPTED_STATUS)
      end
    end

    trait :blacklisted do
      status "blacklisted"
    end
  end
end
