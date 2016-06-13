FactoryGirl.define do
  factory :marketing_referers do
    sequence(:name) {|i| "name#{i}"}
  end
end
