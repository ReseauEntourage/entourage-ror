FactoryBot.define do
  factory :user_application do
    sequence(:push_token) {|n| "MyString#{n}" }
    device_family     { 'MyString' }
    version       { 'MyString' }
    device_os { UserApplication::ANDROID }
    association :user, factory: :pro_user
  end

end
