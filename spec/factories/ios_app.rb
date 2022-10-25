FactoryBot.define do
  factory :ios_app, class: Rpush::Apnsp8::App do
    name { :entourage }
    environment { :development }
    apn_key { :apn_key }
    apn_key_id { :apn_key_id }
    team_id { :team_id }
    bundle_id { :bundle_id }
    connections { 1 }  end
end
