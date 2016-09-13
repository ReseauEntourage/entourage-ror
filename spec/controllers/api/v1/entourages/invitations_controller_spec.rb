require 'rails_helper'

describe Api::V1::Entourages::InvitationsController do

  let(:user) { FactoryGirl.create(:pro_user) }
  let(:entourage) { FactoryGirl.create(:entourage) }
  let(:result) { JSON.parse(response.body) }

  describe 'POST create' do
    context "user not signed in" do
      before { post :create, entourage_id: entourage.to_param }
      it { expect(response.status).to eq(401) }
    end

    context "user signed in" do
      context "inviter accepted in entourage" do
        before { FactoryGirl.create(:join_request, user: user, joinable: entourage, status: JoinRequest::ACCEPTED_STATUS) }

        context "valid params" do
          before { post :create, entourage_id: entourage.to_param, invite: {mode: "SMS", phone_numbers: ["+33612345678", "+33612345679"]}, token: user.token }
          it { expect(EntourageInvitation.count).to eq(2) }
          it { expect(User.count).to eq(4) }
          it { expect(User.where(id: EntourageInvitation.last.invitee_id)).to_not be_nil }
          it { expect(UserRelationship.count).to eq(2) }
          it { expect(UserRelationship.last.target_user).to eq(EntourageInvitation.last.invitee) }
          it { expect(result).to eq({"successfull_numbers"=>["+33612345678", "+33612345679"]}) }
        end

        context "phone number with spaces" do
          before { post :create, entourage_id: entourage.to_param, invite: {mode: "SMS", phone_numbers: ["+40 744 219 491"]}, token: user.token }
          it { expect(EntourageInvitation.count).to eq(1) }
        end

        it "sends sms if valid params" do
          expect(SmsSenderJob).to receive(:perform_later).twice
          post :create, entourage_id: entourage.to_param, invite: {mode: "SMS", phone_numbers: ["+33612345678", "+33612345679"]}, token: user.token
        end

        context "invitation already exists" do
          context "user has already connected to entourage" do
            let!(:existing_user) { FactoryGirl.create(:public_user, phone: "+33612345678") }
            let!(:entourage_invitation) { FactoryGirl.create(:entourage_invitation, invitable: entourage, inviter: user, phone_number: "+33612345678") }
            before { expect_any_instance_of(PushNotificationService).to receive(:send_notification).with("John D", 'Invitation à rejoindre un entourage', "Vous ête invité à rejoindre l'entourage de John D", [existing_user], {type: "ENTOURAGE_INVITATION", entourage_id: entourage.id, inviter_id: user.id, invitee_id: existing_user.id, invitation_id: 123}) }
            before { post :create, entourage_id: entourage.to_param, invite: {mode: "SMS", phone_numbers: ["+33612345678"]}, token: user.token }
            it { expect(EntourageInvitation.all).to eq([entourage_invitation]) }
            it { expect(response.status).to eq(201) }
          end

          context "user never used his entourage account" do
            it "sends a SMS" do
              existing_user = FactoryGirl.create(:public_user, phone: "+33612345678", last_sign_in_at: nil)
              entourage_invitation = FactoryGirl.create(:entourage_invitation, invitable: entourage, inviter: user, phone_number: "+33612345678")
              expect(SmsSenderJob).to receive(:perform_later)
              post :create, entourage_id: entourage.to_param, invite: {mode: "SMS", phone_numbers: ["+33612345678"]}, token: user.token
            end
          end
        end

        context "a user with same phone number already exists" do
          let!(:existing_user) { FactoryGirl.create(:public_user, phone: "+33612345678") }
          before { post :create, entourage_id: entourage.to_param, invite: {mode: "SMS", phone_numbers: ["+33612345678"]}, token: user.token }
          it { expect(EntourageInvitation.count).to eq(1) }
          it { expect(User.count).to eq(3) }
        end

        it "sends notif to invitee" do
          existing_user = FactoryGirl.create(:public_user, phone: "+33612345678")
          expect_any_instance_of(PushNotificationService).to receive(:send_notification).with("John D", 'Invitation à rejoindre un entourage', "Vous ête invité à rejoindre l'entourage de John D", [existing_user], {type: "ENTOURAGE_INVITATION", entourage_id: entourage.id, inviter_id: user.id, invitee_id: existing_user.id, invitation_id: 123})
          post :create, entourage_id: entourage.to_param, invite: {mode: "SMS", phone_numbers: ["+33612345678"]}, token: user.token
        end

        it "doesn't sends sms if user already exists" do
          FactoryGirl.create(:entourage_invitation, invitable: entourage, inviter: user, phone_number: "+33612345678")
          expect(SmsSenderJob).to_not receive(:perform_later)
          post :create, entourage_id: entourage.to_param, invite: {mode: "SMS", phone_numbers: ["+33612345678"]}, token: user.token
        end
      end

      context "invite to an entourage i'm not part of" do
        let(:entourage_invitation) { FactoryGirl.create(:entourage_invitation, invitable: entourage, inviter: user, phone_number: "+33612345678") }
        before { post :create, entourage_id: entourage.to_param, invite: {mode: "SMS", phone_numbers: ["+33612345678"]}, token: user.token }
        it { expect(response.status).to eq(403) }
      end
    end

  end
end