require 'rails_helper'

describe FollowingJob do
  let(:partner) { create :partner, name: "PARTNER_NAME" }
  let(:partner_user) { create :public_user, partner: partner }
  let!(:following) { create :following, partner: partner }

  describe ".on_create_entourage with invitation" do
    let(:action) { create :entourage, user: partner_user }

    subject { FollowingJob.perform_later(action) }

    it { expect { subject }.to change { EntourageInvitation.count }.by(1) }

    it {
      subject
      expect(EntourageInvitation.last.attributes).to include(
        "invitable_id" => action.id,
        "inviter_id" => partner_user.id,
        "invitee_id" => following.user.id,
        "invitation_mode" => "partner_following",
        "phone_number" => following.user.phone,
        "status" => "pending"
      )
    }

    it {
      expect_any_instance_of(PushNotificationService).to receive(:send_notification).with(
        "PARTNER_NAME",
        "Foobar",
        "PARTNER_NAME vous invite à rejoindre une action.",
        [following.user],
        {
          type: "ENTOURAGE_INVITATION",
          entourage_id: action.id,
          group_type: 'action',
          inviter_id: partner_user.id,
          invitee_id: following.user.id,
          invitation_id: 123
        }
      )
      subject
    }

    it {
      expect { subject }.to change { UserServices::UnreadMessages.new(user: following.user).number_of_unread_messages }.by(1)
    }
  end

  describe ".on_create_entourage with invitation" do
    let(:action) { create :entourage, user: partner_user, invite_followers: true }

    subject { FollowingJob.perform_later(action) }

    it { expect { subject }.to change { EntourageInvitation.count }.by(1) }
    it {
      expect_any_instance_of(PushNotificationService).to receive(:send_notification)
      subject
    }
  end

  describe ".on_create_entourage without invitation" do
    let(:action) { create :entourage, user: partner_user, invite_followers: false }

    subject { FollowingJob.perform_later(action) }

    it { expect { subject }.to_not change { EntourageInvitation.count } }
    it {
      expect_any_instance_of(PushNotificationService).to_not receive(:send_notification)
      subject
    }
  end

  describe ".on_create_entourage without invitation on falsy string" do
    let(:action) { create :entourage, user: partner_user, invite_followers: "false" }

    subject { FollowingJob.perform_later(action) }

    it { expect { subject }.to_not change { EntourageInvitation.count } }
    it {
      expect_any_instance_of(PushNotificationService).to_not receive(:send_notification)
      subject
    }
  end
end