FactoryGirl.define do

  factory :user do
    sequence :email do |n|
      "user#{n}@mail.com"
    end
    device_type :android
    sequence :device_id do |n|
      "device id #{n}"
    end
  end
end