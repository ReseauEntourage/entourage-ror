FactoryGirl.define do
  factory :user_application do
    push_token    "MyString"
    device_os     "MyString"
    version       "MyString"
    device_family UserApplication::ANDROID
    association :user, factory: :pro_user
  end

end
