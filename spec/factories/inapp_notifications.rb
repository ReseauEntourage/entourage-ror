FactoryBot.define do
  factory :inapp_notification do
    user { association(:public_user) }
    instance { :neighborhood }
    instance_id { association(:neighborhood).id }
  end
end
