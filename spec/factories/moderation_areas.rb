FactoryGirl.define do
  factory :moderation_area do
    departement '99'
    name "Zone 1"
    welcome_message_1_offer_help   "WELCOME {{first_name}} (R)"
    welcome_message_2_offer_help   "SEE YOU SOON (R)"
    welcome_message_1_ask_for_help "WELCOME {{first_name}} (S)"
    welcome_message_2_ask_for_help "SEE YOU SOON (S)"
    welcome_message_1_organization "WELCOME {{first_name}} (A)"
    welcome_message_2_organization "SEE YOU SOON (A)"
  end
end
