FactoryBot.define do
  factory :inapp_notification do
    user { association(:public_user) }
    instance { :neighborhood }
    instance_id { association(:neighborhood).id }

    trait :obsolete do
      created_at { Time.now - InappNotificationServices::Builder::OBSOLETE_PERIOD - 1.hour }
    end
  end
end
