FactoryBot.define do
  factory :following do
    association :user, factory: :public_user
    association :partner
    active { true }
  end
end
