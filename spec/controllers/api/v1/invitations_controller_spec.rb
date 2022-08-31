require 'rails_helper'

describe Api::V1::InvitationsController do
  let(:user) { FactoryBot.create(:pro_user) }
  let(:result) { JSON.parse(response.body) }

  describe 'GET index' do
    context "user not signed in" do
      before { get :index }
      it { expect(response.status).to eq(401) }
    end

    context "user signed in" do
      let!(:invitation) { FactoryBot.create(:entourage_invitation, invitee: user) }
      before { get :index, params: { token: user.token } }
      it { expect(response.status).to eq(200) }
      it { expect(result).to eq({
        "invitations"=>[{
          "id" => invitation.id,
          "invitation_mode" => "SMS",
          "phone_number" => "+33612345678",
          "entourage_id" => invitation.invitable_id,
          "title" => invitation.invitable.title,
          "status" => "pending",
          "inviter" => {
            "display_name" => "John D."
          }
        }]
      }) }
    end

    context "accepted invitation" do
      let!(:accepted_invitation) { FactoryBot.create(:entourage_invitation, invitee: user) }
      let!(:join_request) { create(:join_request, user: user, joinable: accepted_invitation.invitable, status: JoinRequest::ACCEPTED_STATUS) }
      before { get :index, params: { token: user.token } }
      it { expect(result["invitations"][0]["status"]).to eq("accepted")}
    end

    context "rejected invitation" do
      let!(:rejected_invitation) { FactoryBot.create(:entourage_invitation, invitee: user) }
      let!(:join_request) { create(:join_request, user: user, joinable: rejected_invitation.invitable, status: JoinRequest::REJECTED_STATUS) }
      before { get :index, params: { token: user.token } }
      it { expect(result["invitations"][0]["status"]).to eq("rejected")}
    end

    context "cancelled invitation" do
      let!(:cancelled_invitation) { FactoryBot.create(:entourage_invitation, invitee: user) }
      let!(:join_request) { create(:join_request, user: user, joinable: cancelled_invitation.invitable, status: JoinRequest::CANCELLED_STATUS) }
      before { get :index, params: { token: user.token } }
      it { expect(result["invitations"][0]["status"]).to eq("cancelled")}
    end

    context "belongs to entourage" do
      let!(:entourage) { FactoryBot.create(:entourage) }
      before { FactoryBot.create(:join_request, user: user, joinable: entourage, status: JoinRequest::ACCEPTED_STATUS) }
      let!(:invitation) { FactoryBot.create(:entourage_invitation, invitee: user, invitable: entourage ) }
      before { get :index, params: { token: user.token } }
      it { expect(result["invitations"][0]["status"]).to eq("accepted") }
    end

    context "filter accepted invitations" do
      let!(:accepted_invitation) { FactoryBot.create(:entourage_invitation, invitee: user, status: "accepted") }
      let!(:pending_invitation) { FactoryBot.create(:entourage_invitation, invitee: user, status: "pending") }
      let!(:rejected_invitation) { FactoryBot.create(:entourage_invitation, invitee: user, status: "rejected") }
      let!(:cancelled_invitation) { FactoryBot.create(:entourage_invitation, invitee: user, status: "cancelled") }
      before { get :index, params: { token: user.token, status: "accepted" } }
      it { expect(result["invitations"].map {|invite| invite["id"]}).to eq([accepted_invitation.id])}
    end
  end

  describe "PUT update" do
    let(:group) { create :entourage, :joined }
    let!(:invitation) { FactoryBot.create(:entourage_invitation, invitee: user, invitable: group) }
    context "user not signed in" do
      before { put :update, params: { id: invitation.to_param }}
      it { expect(response.status).to eq(401) }
    end

    context "user signed in" do
      context "accept my invite" do
        before { put :update, params: { id: invitation.to_param, token: user.token } }
        it { expect(response.status).to eq(204) }
        it { expect(JoinRequest.where(user: invitation.invitee, joinable: invitation.invitable, status: JoinRequest::ACCEPTED_STATUS).count).to eq(1) }
        it { expect(EntourageInvitation.last.status).to eq(EntourageInvitation::ACCEPTED_STATUS) }
        it { expect(invitation.invitable.reload.number_of_people).to eq invitation.invitable.join_requests.accepted.count }
      end

      context "accept another user invite" do
        let!(:invitation) { FactoryBot.create(:entourage_invitation, invitee: FactoryBot.create(:public_user)) }
        before { put :update, params: { id: invitation.to_param, token: user.token } }
        it { expect(response.status).to eq(403) }
        it { expect(JoinRequest.where(user: invitation.invitee, joinable: invitation.invitable, status: JoinRequest::ACCEPTED_STATUS).count).to eq(0) }
      end

      it "sends notification for accepted invitation" do
        expect_any_instance_of(PushNotificationService).to receive(:send_notification).with(
          "John D.",
          "Foobar",
          "John D. a accepté votre invitation",
          [invitation.inviter],
          {
            type: "INVITATION_STATUS",
            inviter_id: invitation.inviter_id,
            invitee_id: invitation.invitee_id,
            feed_id: invitation.invitable_id,
            feed_type: "Entourage",
            group_type: 'action',
            accepted: true,
            instance: "conversations",
            id: group.id
          }
        )

        put :update, params: { id: invitation.to_param, token: user.token }
      end
    end
  end

  describe "DELETE destroy" do
    let!(:invitation) { FactoryBot.create(:entourage_invitation, invitee: user) }
    context "user not signed in" do
      before { delete :destroy, params: { id: invitation.to_param }}
      it { expect(response.status).to eq(401) }
    end

    context "user signed in" do
      context "refuse my invite" do
        before { delete :destroy, params: { id: invitation.to_param, token: user.token } }
        it { expect(response.status).to eq(204) }
        it { expect(JoinRequest.where(user: invitation.invitee, joinable: invitation.invitable, status: JoinRequest::REJECTED_STATUS).count).to eq(1) }
        it { expect(EntourageInvitation.last.status).to eq(EntourageInvitation::REJECTED_STATUS) }
      end

      context "refuse another user invite" do
        let!(:invitation) { FactoryBot.create(:entourage_invitation, invitee: FactoryBot.create(:public_user)) }
        before { delete :destroy, params: { id: invitation.to_param, token: user.token } }
        it { expect(response.status).to eq(403) }
        it { expect(JoinRequest.where(user: invitation.invitee, joinable: invitation.invitable, status: JoinRequest::REJECTED_STATUS).count).to eq(0) }
      end

      it "sends notification for accepted invitation" do
        expect_any_instance_of(PushNotificationService).to receive(:send_notification).with(
          "John D.",
          "Foobar",
          "John D. a refusé votre invitation",
          [invitation.inviter],
          {
            type: "INVITATION_STATUS",
            inviter_id: invitation.inviter_id,
            invitee_id: invitation.invitee_id,
            feed_id: invitation.invitable_id,
            feed_type: "Entourage",
            group_type: 'action',
            accepted: false,
            instance: "conversations",
            id: invitation.invitable_id
          }
        )

        delete :destroy, params: { id: invitation.to_param, token: user.token }
      end
    end
  end
end
