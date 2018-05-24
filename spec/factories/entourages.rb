FactoryGirl.define do
  factory :entourage do
    transient do
      join_request_user nil
      community 'entourage'
    end

    uuid { SecureRandom.uuid }
    status "open"
    title "foobar"
    entourage_type "ask_for_help"
    display_category "social"
    association :user, factory: :public_user
    latitude 1.122
    longitude 2.345
    number_of_people 1

    after(:build) do |entourage, stuff|
      user_specified = stuff.methods(false).include?(:user)
      next if user_specified

      entourage.user.update_attributes!(community: stuff.community)
      entourage.community = stuff.community
    end

    trait :joined do
      after(:create) do |entourage, evaluator|
        FactoryGirl.create(:join_request, joinable: entourage, user: evaluator.join_request_user || entourage.user, status: JoinRequest::ACCEPTED_STATUS)
      end
    end

    trait :blacklisted do
      status "blacklisted"
    end
  end
end
