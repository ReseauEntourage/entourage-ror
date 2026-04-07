FactoryBot.define do
  factory :smalltalk do
    match_format { :many }
    number_of_people { 2 }

    transient do
      participants { [] }
    end

    after(:create) do |smalltalk, stuff|
      stuff.participants.each do |participant|
        create :join_request, joinable: smalltalk, user: participant, status: JoinRequest::ACCEPTED_STATUS
      end
    end

    trait :one_format do
      match_format { :one }
    end

    trait :many_format do
      match_format { :many }
    end

    trait :completed do
      completed_at { Time.current }
    end

    trait :closed do
      closed_at { Time.current }
    end

    trait :with_meeting do
      after(:create) do |smalltalk|
        smalltalk.update!(meeting: create(:meeting))
      end
    end
  end
end
