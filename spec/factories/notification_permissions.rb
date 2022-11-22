FactoryBot.define do
  factory :notification_permission do
    user { association :public_user }
    permissions { {
      neighborhood: true,
      outing: true,
      private_chat_message: true
    } }
  end
end
