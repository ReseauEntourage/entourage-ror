FactoryGirl.define do
  factory :tours_user do
    association :user, factory: :pro_user
    tour
    status "pending"
  end

end
