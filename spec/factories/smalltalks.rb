FactoryBot.define do
  factory :smalltalk do
    transient do
      participants { [] }
    end

    after(:create) do |smalltalk, stuff|
      stuff.participants.each do |participant|
        create :join_request, joinable: smalltalk, user: participant, status: JoinRequest::ACCEPTED_STATUS
      end
    end
  end
end
