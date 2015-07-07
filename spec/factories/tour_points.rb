# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :tour_point do
    latitude 1.5
    longitude 1.5
    tour
    passing_time "2015-07-07 12:31:43"
  end
end
