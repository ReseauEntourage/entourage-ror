FactoryBot.define do
  factory :recurrence_rule do
    association :created_by, factory: :pro_user
    frequency { 'daily' }
    ends_on { 1.month.from_now.to_date }
    active { true }
  end
end
