# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :encounter do
    date "2014-10-11 15:19:45"
    street_person_name "Toto"
    message "Toto fait du velo."
    voice_message_url "https://www.google.com"
    latitude 48.870424
    longitude 2.3068194999999605
    tour
  end
end