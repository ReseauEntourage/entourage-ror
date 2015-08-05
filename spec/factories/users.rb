FactoryGirl.define do

  factory :user do
    sequence :email do |n|
      "user#{n}@mail.com"
    end
    device_type :android
    sequence :device_id do |n|
      "device id #{n}"
    end
    sequence :phone do |n|
      "00 11 22 33 #{n}"
    end
  end
end