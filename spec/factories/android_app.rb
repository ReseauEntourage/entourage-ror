FactoryGirl.define do
  factory :android_app, class: Rpush::Gcm::App do
    name 'entourage'
    auth_key 'auth_key'
  end
end
