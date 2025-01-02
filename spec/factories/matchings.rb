FactoryBot.define do
  factory :matching do
    instance { association :contribution }
    match { association :resource }
  end
end
