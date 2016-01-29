FactoryGirl.define do
  factory :tours_user do
    user
    tour
    status "pending"
  end

end
