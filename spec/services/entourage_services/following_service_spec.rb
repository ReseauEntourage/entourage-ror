require 'rails_helper'

describe FollowingService do
  let(:partner) { create :partner, name: "PARTNER_NAME" }
  let(:partner_user) { create :public_user, partner: partner }
  let!(:following) { create :following, partner: partner }
  let(:action) { create :entourage, :moderation_validated, user: partner_user }

  describe ".on_create_entourage" do
    subject { FollowingService.on_create_entourage(action) }

    context "create entourage_invitation" do
      it { expect { subject }.to change { EntourageInvitation.count }.by(1) }
    end

    context "update unread_messages" do
      it {
        expect { subject }.to change {
          UserServices::UnreadMessages.new(user: following.user).number_of_unread_messages
        }.by(0)
      }
    end

    context "entourage_invitation attributes" do
      before { subject }

      it {
        expect(EntourageInvitation.last.attributes).to include(
          "invitable_id" => action.id,
          "inviter_id" => partner_user.id,
          "invitee_id" => following.user.id,
          "invitation_mode" => "partner_following",
          "phone_number" => following.user.phone,
          "status" => "pending"
        )
      }
    end

    context "send_notification" do
      let(:notification_service) { spy }

      before { PushNotificationService.stub(:new) { notification_service } }
      before { subject }

      it {
        expect(notification_service).to have_received(:send_notification).with(
          nil,
          action.title,
          "#{partner.name} vous invite à rejoindre #{action.title}",
          [following.user],
          "solicitation",
          action.id,
          {
            :instance => "solicitation",
            :instance_id => action.id,
            :type => "ENTOURAGE_INVITATION",
            :entourage_id => action.id,
            :group_type => 'action',
            :inviter_id => partner_user.id,
            :invitee_id => following.user.id,
            :invitation_id => nil,
          }
        )
      }
    end
  end
end
