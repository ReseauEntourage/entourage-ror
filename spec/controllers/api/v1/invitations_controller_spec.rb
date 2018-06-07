require 'rails_helper'

describe Api::V1::InvitationsController do

  let(:user) { FactoryGirl.create(:pro_user) }
  let(:result) { JSON.parse(response.body) }

  describe 'GET index' do
    context "user not signed in" do
      before { get :index }
      it { expect(response.status).to eq(401) }
    end

    context "user signed in" do
      let!(:invitation) { FactoryGirl.create(:entourage_invitation, invitee: user) }
      before { get :index, token: user.token }
      it { expect(response.status).to eq(200) }
      it { expect(result).to eq({"invitations"=>[
                                                  {
                                                    "id"=>invitation.id,
                                                    "invitation_mode"=>"SMS",
                                                    "phone_number"=>"+33612345678",
                                                    "entourage_id"=>invitation.invitable_id,
                                                    "status"=>"pending",
                                                    "inviter"=>{
                                                        "id"=>invitation.inviter_id,
                                                        "display_name"=>"John D",
                                                        "first_name"=>"John",
                                                        "last_name"=>"Doe",
                                                        "roles"=>[],
                                                        "about"=>nil,
                                                        "avatar_url"=>nil,
                                                        "user_type"=>"pro",
                                                        "organization"=>{
                                                            "name"=>invitation.inviter.organization.name,
                                                            "description"=>"Association description",
                                                            "phone"=>invitation.inviter.organization.phone,
                                                            "address"=>invitation.inviter.organization.address,
                                                            "logo_url"=>nil
                                                        },
                                                        "stats"=>{
                                                            "tour_count"=>0,
                                                            "encounter_count"=>0,
                                                            "entourage_count"=>0,
                                                        },
                                                        "partner"=>nil
                                                    }
                                                  }
                                                ]}) }

    end

    context "accepted invitation" do
      let!(:accepted_invitation) { FactoryGirl.create(:entourage_invitation, invitee: user) }
      let!(:join_request) { create(:join_request, user: user, joinable: accepted_invitation.invitable, status: JoinRequest::ACCEPTED_STATUS) }
      before { get :index, token: user.token }
      it { expect(result["invitations"][0]["status"]).to eq("accepted")}
    end

    context "rejected invitation" do
      let!(:rejected_invitation) { FactoryGirl.create(:entourage_invitation, invitee: user) }
      let!(:join_request) { create(:join_request, user: user, joinable: rejected_invitation.invitable, status: JoinRequest::REJECTED_STATUS) }
      before { get :index, token: user.token }
      it { expect(result["invitations"][0]["status"]).to eq("rejected")}
    end

    context "cancelled invitation" do
      let!(:cancelled_invitation) { FactoryGirl.create(:entourage_invitation, invitee: user) }
      let!(:join_request) { create(:join_request, user: user, joinable: cancelled_invitation.invitable, status: JoinRequest::CANCELLED_STATUS) }
      before { get :index, token: user.token }
      it { expect(result["invitations"][0]["status"]).to eq("cancelled")}
    end

    context "belongs to entourage" do
      let!(:entourage) { FactoryGirl.create(:entourage) }
      before { FactoryGirl.create(:join_request, user: user, joinable: entourage, status: JoinRequest::ACCEPTED_STATUS) }
      let!(:invitation) { FactoryGirl.create(:entourage_invitation, invitee: user, invitable: entourage ) }
      before { get :index, token: user.token }
      it { expect(result["invitations"][0]["status"]).to eq("accepted") }
    end

    context "filter accepted invitations" do
      let!(:accepted_invitation) { FactoryGirl.create(:entourage_invitation, invitee: user, status: "accepted") }
      let!(:pending_invitation) { FactoryGirl.create(:entourage_invitation, invitee: user, status: "pending") }
      let!(:rejected_invitation) { FactoryGirl.create(:entourage_invitation, invitee: user, status: "rejected") }
      let!(:cancelled_invitation) { FactoryGirl.create(:entourage_invitation, invitee: user, status: "cancelled") }
      before { get :index, token: user.token, status: "accepted" }
      it { expect(result["invitations"].map {|invite| invite["id"]}).to eq([accepted_invitation.id])}
    end
  end

  describe "PUT update" do
    let!(:invitation) { FactoryGirl.create(:entourage_invitation, invitee: user) }
    context "user not signed in" do
      before { put :update, id: invitation.to_param}
      it { expect(response.status).to eq(401) }
    end

    context "user signed in" do
      context "accept my invite" do
        before { put :update, id: invitation.to_param, token: user.token }
        it { expect(response.status).to eq(204) }
        it { expect(JoinRequest.where(user: invitation.invitee, joinable: invitation.invitable, status: JoinRequest::ACCEPTED_STATUS).count).to eq(1) }
        it { expect(EntourageInvitation.last.status).to eq(EntourageInvitation::ACCEPTED_STATUS) }
      end

      context "accept another user invite" do
        let!(:invitation) { FactoryGirl.create(:entourage_invitation, invitee: FactoryGirl.create(:public_user)) }
        before { put :update, id: invitation.to_param, token: user.token }
        it { expect(response.status).to eq(403) }
        it { expect(JoinRequest.where(user: invitation.invitee, joinable: invitation.invitable, status: JoinRequest::ACCEPTED_STATUS).count).to eq(0) }
      end

      it "sends notification for accepted invitation" do
        expect_any_instance_of(PushNotificationService).to receive(:send_notification).with("John D",
                                                                                            "Invitation acceptée",
                                                                                            "John D a accepté votre invitation",
                                                                                            [invitation.inviter],
                                                                                            {type: "INVITATION_STATUS",
                                                                                             inviter_id: invitation.inviter_id,
                                                                                             invitee_id: invitation.invitee_id,
                                                                                             feed_id: invitation.invitable_id,
                                                                                             feed_type: "Entourage",
                                                                                             accepted: true})
        put :update, id: invitation.to_param, token: user.token
      end
    end
  end

  describe "DELETE destroy" do
    let!(:invitation) { FactoryGirl.create(:entourage_invitation, invitee: user) }
    context "user not signed in" do
      before { delete :destroy, id: invitation.to_param}
      it { expect(response.status).to eq(401) }
    end

    context "user signed in" do
      context "refuse my invite" do
        before { delete :destroy, id: invitation.to_param, token: user.token }
        it { expect(response.status).to eq(204) }
        it { expect(JoinRequest.where(user: invitation.invitee, joinable: invitation.invitable, status: JoinRequest::REJECTED_STATUS).count).to eq(1) }
        it { expect(EntourageInvitation.last.status).to eq(EntourageInvitation::REJECTED_STATUS) }
      end

      context "refuse another user invite" do
        let!(:invitation) { FactoryGirl.create(:entourage_invitation, invitee: FactoryGirl.create(:public_user)) }
        before { delete :destroy, id: invitation.to_param, token: user.token }
        it { expect(response.status).to eq(403) }
        it { expect(JoinRequest.where(user: invitation.invitee, joinable: invitation.invitable, status: JoinRequest::REJECTED_STATUS).count).to eq(0) }
      end

      it "sends notification for accepted invitation" do
        expect_any_instance_of(PushNotificationService).to receive(:send_notification).with("John D",
                                                                                            "Invitation refusée",
                                                                                            "John D a refusé votre invitation",
                                                                                            [invitation.inviter],
                                                                                            {type: "INVITATION_STATUS",
                                                                                             inviter_id: invitation.inviter_id,
                                                                                             invitee_id: invitation.invitee_id,
                                                                                             feed_id: invitation.invitable_id,
                                                                                             feed_type: "Entourage",
                                                                                             accepted: false})
        delete :destroy, id: invitation.to_param, token: user.token
      end
    end
  end
end