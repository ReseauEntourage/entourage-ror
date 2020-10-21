# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :poi do
    name "Dede"
    latitude 48.870424
    longitude 2.30681949999996
    adress "Au 50 75008 Paris"
    phone "0000000000"
    website "entourage.com"
    email "entourage@entourage.com"
    audience "Mon audience"
    category_id 1
    validated true
    category

    after(:create) do |poi, _|
      poi.categories << poi.category
    end
  end
end
