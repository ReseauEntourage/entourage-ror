FactoryBot.define do
  factory :scheduled_publication do
    association :author, factory: :pro_user
    scheduled_at { 1.day.from_now }
    status { 'pending' }

    trait :post do
      association :publishable, factory: [:chat_message, :neighborhood_post], status: 'scheduled'
      neighborhood_id { publishable.messageable_id }
    end

    trait :broadcast do
      association :publishable, factory: :neighborhood_message_broadcast, status: 'scheduled'
    end
  end
end
