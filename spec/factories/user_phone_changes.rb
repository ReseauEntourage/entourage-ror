FactoryBot.define do
  factory :user_phone_change do
    previous_phone { '+33600000000' }
    phone { '+33600000001' }
    email { 'foo@bar.email' }

    trait :request do
      kind { 'request' }
    end

    trait :change do
      kind { 'change' }
    end

    trait :cancel do
      kind { 'cancel' }
    end


    factory :user_phone_change_request, traits: [:request]
    factory :user_phone_change_change, traits: [:change]
    factory :user_phone_change_cancel, traits: [:cancel]
  end
end
