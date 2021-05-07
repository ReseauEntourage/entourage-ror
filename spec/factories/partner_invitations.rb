FactoryBot.define do
  factory :partner_invitation do
    association :partner, factory: :partner
    association :inviter, factory: :pro_user
    association :invitee, factory: :public_user

    invitee_email { 'invitee@email.social' }
    token { '0123456789abcdef' * 4 }
    invited_at { '2021-01-01 12:00:00' }
    status { 'accepted' }
  end
end
