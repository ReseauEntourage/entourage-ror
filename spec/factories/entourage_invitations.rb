FactoryBot.define do
  factory :entourage_invitation do
    association :invitable, factory: :entourage
    association :inviter, factory: :pro_user
    association :invitee, factory: :pro_user
    invitation_mode { 'SMS' }
    phone_number    { '+33612345678' }

    trait :accepted do
      status { EntourageInvitation::ACCEPTED_STATUS }
    end
  end

end
