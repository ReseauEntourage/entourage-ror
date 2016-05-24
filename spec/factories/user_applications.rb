FactoryGirl.define do
  factory :user_application do
    sequence(:push_token) {|n| "MyString#{n}" }
    device_os     "MyString"
    version       "MyString"
    device_family UserApplication::ANDROID
    association :user, factory: :pro_user
  end

end
