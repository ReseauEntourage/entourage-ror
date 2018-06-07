FactoryGirl.define do
  factory :entourage do
    transient do
      join_request_user nil
      community { $server_community.slug }
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
      user_specified = stuff.methods(false)

      unless user_specified.include?(:user)
        entourage.user.update_attributes!(community: stuff.community)
        entourage.community = entourage.user.community
      end

      unless user_specified.include?(:group_type)
        entourage.group_type =
          entourage.user.community.group_types.keys.first
      end
    end

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
  end
end
