FactoryBot.define do
  factory :inapp_notification do
    user { association(:public_user) }
    instance { :neighborhood }
    instance_id { association(:neighborhood).id }

    trait :obsolete do
      created_at { Time.now - InappNotificationServices::Builder::OBSOLETE_PERIOD - 1.hour }
    end

    trait :neighborhood_post do
      instance { :neighborhood_post }
      instance_id { association(:neighborhood).id }
      post_id { association(:chat_message, :neighborhood_post).id }
    end
  end
end
