FactoryBot.define do
  factory :lexical_transformation do
    association :instance, factory: :neighborhood
  end
end
