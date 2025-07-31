FactoryBot.define do
  factory :android_app, class: Rpush::Fcm::App do
    name { 'entourage' }
    auth_key { 'auth_key' }
  end
end
