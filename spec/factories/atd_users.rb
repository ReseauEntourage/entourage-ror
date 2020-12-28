FactoryBot.define do
  factory :atd_user do
    sequence(:atd_id) {|n| n}
    sequence(:tel_hash) {|n| "MyString#{n}"}
    sequence(:mail_hash) {|n| "MyString#{n}"}
  end
end
