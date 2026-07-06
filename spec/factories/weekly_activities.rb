FactoryBot.define do
  factory :weekly_activity do
    association :user, factory: :public_user
    week_iso { Date.today.strftime('%G-W%V') }
  end
end
