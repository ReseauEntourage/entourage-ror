FactoryGirl.define do
  factory :moderation_area do
    departement '99'
    name "Zone 1"
    welcome_message_1 "WELCOME {{first_name}}"
    welcome_message_2 "SEE YOU SOON"
  end
end
