FactoryGirl.define do
  factory :entourage do
    transient do
      join_request_user nil
      community { $server_community.slug }
    end

    uuid { SecureRandom.uuid }
    status "open"
    title "foobar"
    group_type "action"
    entourage_type "ask_for_help"
    display_category "social"
    user { association :public_user, community: community }
    latitude 1.122
    longitude 2.345
    number_of_people 1

    trait :joined do
      after(:create) do |entourage, evaluator|
        user = evaluator.join_request_user || entourage.user
        role = user == entourage.user ? :creator : :member
        FactoryGirl.create(:join_request, joinable: entourage, user: user, role: role, status: JoinRequest::ACCEPTED_STATUS)
      end
    end

    trait :blacklisted do
      status "blacklisted"
    end

    factory :private_circle do
      group_type "private_circle"
    end

    factory :neighborhood do
      group_type "neighborhood"
    end
  end
end
