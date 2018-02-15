FactoryGirl.define do
  factory :action_zone do
    association :user, factory: :public_user
    postal_code '75012'
    country 'FR'
  end
end
