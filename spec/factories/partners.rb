FactoryBot.define do
  factory :partner do
    name { 'MyString' }
    description { 'MyDescription' }
    latitude { 49 }
    longitude { 2.3 }
    address { '174 rue Championnet, Paris' }
    large_logo_url { 'MyString' }
  end
end
