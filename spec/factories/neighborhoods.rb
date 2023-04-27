FactoryBot.define do
  factory :neighborhood do
    user { association :public_user }
    name { 'Foot Paris 17è' }
    description { 'Pour les passionnés de foot du 17è' }
    interests { [:sport] }
    latitude { 48.86 }
    longitude { 2.35 }

    transient do
      participants { [] }
      cancelled_participants { [] }
    end

    after(:create) do |neighborhood, stuff|
      (stuff.participants - [neighborhood.user]).each do |participant|
        create :join_request, joinable: neighborhood, user: participant, status: JoinRequest::ACCEPTED_STATUS
      end

      (stuff.cancelled_participants - [neighborhood.user]).each do |cancelled_participant|
        create :join_request, joinable: neighborhood, user: cancelled_participant, status: JoinRequest::CANCELLED_STATUS
      end
    end
  end
end
