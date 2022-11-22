FactoryBot.define do
  factory :notification_permission do
    user { association :public_user }
    permissions { {
      neighborhood: true,
      outing: true,
      chat_message: true,
      action: true
    } }
  end
end
