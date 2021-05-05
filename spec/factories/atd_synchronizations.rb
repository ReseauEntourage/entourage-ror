FactoryBot.define do
  factory :atd_synchronization do
    sequence(:filename) { |n| "MyString#{n}" }
  end

end
