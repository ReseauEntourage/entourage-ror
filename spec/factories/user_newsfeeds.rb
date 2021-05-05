FactoryBot.define do
  factory :user_newsfeed do
    association :user, factory: :public_user
    latitude { 1.5 }
    longitude { 1.5 }
  end
end
