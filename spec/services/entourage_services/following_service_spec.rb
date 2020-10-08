require 'rails_helper'

describe FollowingService do

  let(:partner) { create :partner }
  let(:partner_user) { create :public_user, partner: partner }
  let!(:following) { create :following, partner: partner }
  let(:action) { create :entourage, user: partner_user }

  describe ".on_create_entourage" do
    subject { FollowingService.on_create_entourage(action) }

    it {
      expect { subject }.to change { EntourageInvitation.count }.by(1)
    }

    it {
      subject
      expect(EntourageInvitation.last.attributes).to include(
        "invitable_id" => action.id,
        "invitable_type" => "Entourage",
        "inviter_id" => partner_user.id,
        "invitee_id" => following.user.id,
        "invitation_mode" => "SMS",
        "phone_number" => following.user.phone,
        "status" => "pending"
      )
    }
  end
end
