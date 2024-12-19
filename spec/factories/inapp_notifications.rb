FactoryBot.define do
  factory :inapp_notification do
    user { association(:public_user) }
    instance { :neighborhood }
    instance_id { association(:neighborhood).id }
    context { :chat_message_on_create }

    after(:build) do |notification, evaluator|
      if evaluator.instance.present?
        notification.instance = evaluator.instance
        notification.instance_id = evaluator.instance_id
      end
    end

    trait :obsolete do
      created_at { Time.now - InappNotificationServices::Builder::OBSOLETE_PERIOD - 1.hour }
    end

    trait :user do
      instance { :user }
      instance_id { association(:public_user).id }
    end

    trait :neighborhood do
      instance { :neighborhood }
      instance_id { association(:neighborhood).id }
    end

    trait :neighborhood_post do
      instance { :neighborhood_post }
      instance_id { association(:neighborhood).id }
      post_id { association(:chat_message, :neighborhood_post).id }
    end

    trait :outing do
      instance { :outing }
      instance_id { association(:outing).id }
    end

    trait :outing_post do
      instance { :outing_post }
      instance_id { association(:outing).id }
      post_id { association(:chat_message, :outing_post).id }
    end
  end
end
