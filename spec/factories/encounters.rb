# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :encounter do
    date "2014-10-10 15:19:45"
    location "MyString"
    member_id 1
    group_id 1
  end
end
