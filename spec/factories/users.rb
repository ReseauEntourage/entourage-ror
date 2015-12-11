FactoryGirl.define do

  factory :user do
    first_name 'John'
    last_name 'Doe'
    sequence :email do |n|
      "user#{n}@mail.com"
    end
    device_type :android
    sequence :device_id do |n|
      "device id #{n}"
    end
    sequence :phone do |n|
      "+336%08i" % n
    end

    sms_code '098765'

    sequence :token do |n|
      "foobar#{n}"
    end
    organization
  end
end