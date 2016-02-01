FactoryGirl.define do
  factory :entourage do
    status "open"
    title "foobar"
    entourage_type "ask_for_help"
    association :user, factory: :public_user
    latitude 1.122
    longitude 2.345
    number_of_people 1
  end
end