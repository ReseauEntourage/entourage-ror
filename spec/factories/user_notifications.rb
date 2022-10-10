FactoryBot.define do
  factory :user_notification do
    user { association(:public_user) }
    action { :show }
    instance { :neighborhood }
    instance_id { association(:neighborhood).id }
  end
end
