FactoryBot.define do
  factory :user do
    first_name { 'John' }
    last_name { 'Doe' }
    deleted { false }
    last_sign_in_at { 1.month.ago }
    sequence :email do |n|
      "user#{n}@mail.com"
    end
    device_type { :android }
    sequence :device_id do |n|
      "device id #{n}"
    end
    sequence :phone do |n|
      "+336%08i" % n
    end

    sms_code { '098765' }
    validation_status { "validated" }

    sequence :token do |n|
      "foobar#{n}"
    end

    community do
      $server_community.slug
    end

    trait :public do
      user_type { 'public' }
    end

    trait :pro do
      user_type { 'pro' }
    end

    trait :paris do
      address
    end

    trait :partner do
      partner { create :partner }
    end

    trait :admin do
      first_name { 'pouet' }
      email { 'guillaume@entourage.social' }
      phone { '+33768037348' }
      user_type { 'pro' }
      admin { true }
    end

    trait :offer_help do
      goal { 'offer_help' }
    end

    factory :pro_user,    traits: [:pro]
    factory :public_user, traits: [:public]
    factory :partner_user, traits: [:public, :partner]
    factory :admin_user,  traits: [:admin]
    factory :offer_help_user,  traits: [:public, :offer_help]
    factory :pro_user_paris, traits: [:pro, :paris]
  end
end
