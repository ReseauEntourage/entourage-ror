FactoryBot.define do
  factory :neighborhood do
    user { association :public_user }
    name { 'Foot Paris 17è' }
    description { 'Pour les passionnés de foot du 17è' }
    interests { [:sport] }
    latitude { 48.86 }
    longitude { 2.35 }
  end
end
