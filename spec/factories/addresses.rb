FactoryGirl.define do
  factory :address do
    place_name "rue Pizza"
    latitude 1.5
    longitude 1.5
    postal_code "75020"
    country 'FR'
    user { association :public_user }
  end
end
