FactoryBot.define do
  factory :survey do
    questions { ["question 1", "question 2"] }
    multiple { false }
  end
end
