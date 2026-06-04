FactoryBot.define do
  factory :users_resource do
    association :user, factory: :public_user
    association :resource
    watched { false }
  end
end
