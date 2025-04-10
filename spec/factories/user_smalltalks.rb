FactoryBot.define do
  factory :user_smalltalk do
    user { association :user }

    match_format { :one }
    match_locality { false }
    match_gender { false }
    match_interest { false }
  end
end
