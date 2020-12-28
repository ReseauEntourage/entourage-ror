FactoryBot.define do
  factory :answer do
    question
    encounter
    value { "foobar" }
  end
end
