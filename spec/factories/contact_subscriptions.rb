FactoryBot.define do
  factory :contact_subscription do
    email { 'foo@bar.fr' }
    name { 'Foo bar' }
    profile { 'profile' }
    subject { 'subject' }
    message { 'message' }
  end
end
