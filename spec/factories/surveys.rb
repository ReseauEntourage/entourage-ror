FactoryBot.define do
  factory :survey do
    choices { ["question 1", "question 2"] }
    multiple { false }
  end
end
