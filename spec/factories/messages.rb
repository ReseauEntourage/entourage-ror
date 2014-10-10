# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :message do
    date "2014-10-10"
    content "MyString"
    member_id 1
    group_id 1
    is_private false
  end
end
