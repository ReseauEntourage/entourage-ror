FactoryBot.define do
  factory :entourage do
    transient do
      join_request_user { nil }
      join_request_role { :auto }
      community { $server_community.slug }
    end

    uuid { SecureRandom.uuid }
    status { "open" }
    title { "foobar" }
    group_type { "action" }
    entourage_type { "ask_for_help" }
    display_category { "social" }
    user { association :public_user, community: community }
    latitude { 1.122 }
    longitude { 2.345 }
    number_of_people { 1 }

    trait :joined do
      after(:create) do |entourage, evaluator|
        user = evaluator.join_request_user || entourage.user
        if evaluator.join_request_role == :auto && entourage.group_type == 'action' && user == entourage.user
          role = :creator
        else
          role = evaluator.join_request_role
        end

        FactoryBot.create(:join_request, joinable: entourage, user: user, role: role, status: JoinRequest::ACCEPTED_STATUS)
      end
    end

    trait :blacklisted do
      status { "blacklisted" }
    end

    factory :outing do
      group_type { "outing" }
      latitude { 48.854367553785 }
      longitude { 2.27034058909627 }

      transient do
        default_metadata { { starts_at: 1.day.from_now.change(hour: 19),
                         place_name: "Café la Renaissance",
                         street_address: "44 rue de l’Assomption, 75016 Paris, France",
                         google_place_id: "foobar" } }
      end

      after(:build) do |outing, stuff|
        outing.metadata = (stuff.default_metadata || {}).symbolize_keys.merge(outing.metadata.symbolize_keys)
      end

      trait :for_neighborhood do
        initialize_with { Outing.new(attributes) }
      end
    end

    factory :conversation do
      group_type { "conversation" }

      transient do
        participants { [] }
      end

      after(:build) do |conversation, stuff|
        conversation.user = stuff.members.first if stuff.members.any?
      end

      after(:create) do |conversation, stuff|
        stuff.participants.each do |participant|
          create :join_request, joinable: conversation, user: participant, status: JoinRequest::ACCEPTED_STATUS
        end
        conversation.reload
      end
    end
  end
end
