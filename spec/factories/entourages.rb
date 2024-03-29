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

    transient do
      participants { [] }
    end

    # status
    trait :open do status { :open } end
    trait :closed do status { :closed } end

    # outcome
    trait :outcome_oui do
      after(:create) do |entourage, evaluator|
        if entourage.moderation.present?
          entourage.moderation.update_attribute(:action_outcome, 'Oui')
        else
          moderation { association :entourage_moderation, :oui }
        end
      end
    end

    trait :outcome_non do
      after(:create) do |entourage, evaluator|
        if entourage.moderation.present?
          entourage.moderation.update_attribute(:action_outcome, 'Non')
        else
          moderation { association :entourage_moderation, :non }
        end
      end
    end

    trait :moderation_validated do
      after(:create) do |entourage, evaluator|
        if entourage.moderation.present?
          entourage.moderation.update_attribute(:validated_at, Time.now)
          entourage.moderation.update_attribute(:moderated_at, Time.now)
        else
          moderation { association :entourage_moderation, :validated }
        end
      end
    end

    trait :moderation_moderated do
      after(:create) do |entourage, evaluator|
        if entourage.moderation.present?
          entourage.moderation.update_attribute(:moderated_at, Time.now)
        else
          moderation { association :entourage_moderation, :moderated }
        end
      end
    end

    after(:create) do |entourage, stuff|
      stuff.participants.each do |participant|
        create :join_request, joinable: entourage, user: participant, status: JoinRequest::ACCEPTED_STATUS
      end
      entourage.reload
    end

    trait :joined do
      after(:create) do |entourage, evaluator|
        next if entourage.is_a?(Solicitation) || entourage.is_a?(Contribution)

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

      trait :with_recurrence do
        recurrency_identifier { SecureRandom.hex(8) }
        initialize_with { Outing.new(attributes) }
        recurrence { association :outing_recurrence, identifier: recurrency_identifier }
      end

      trait :outing_class do
        initialize_with { Outing.new(attributes) }
      end

      trait :with_neighborhood do
        initialize_with { Outing.new(attributes) }
        neighborhoods { [association(:neighborhood, user: user)] }
      end
    end

    factory :contribution do
      entourage_type { "contribution" }
      initialize_with { Contribution.new(attributes) }
    end

    factory :solicitation do
      entourage_type { "ask_for_help" }
      initialize_with { Solicitation.new(attributes) }
    end

    factory :conversation do
      group_type { "conversation" }

      after(:build) do |conversation, stuff|
        conversation.user = stuff.members.first if stuff.members.any?
      end
    end
  end
end
