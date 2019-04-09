FactoryGirl.define do

  sequence :email do |n|
    "subscriber#{n}@newsletter.com"
  end

  factory :newsletter_subscription do
    email
    active true
  end

end
