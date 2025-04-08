FactoryBot.define do
  factory :user_smalltalk do
    match_format { :one }
    match_locality { false }
    match_gender { false }
    match_interest { false }
  end
end
