FactoryGirl.define do
  factory :join_request do
    association :user, factory: :pro_user
    association :joinable, factory: :entourage
    status "pending"
  end

end
