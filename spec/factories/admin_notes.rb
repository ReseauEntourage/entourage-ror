FactoryBot.define do
  factory :admin_note do
    notable { association(:public_user) }
    author { association(:public_user) }
    body { 'Une note interne' }
  end
end
