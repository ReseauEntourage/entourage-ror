require 'rails_helper'

describe Api::V1::Entourages::UsersController do

  let(:user) { FactoryGirl.create(:public_user) }
  let(:entourage) { FactoryGirl.create(:entourage, title: "foobar1") }
  let(:result) { JSON.parse(response.body) }

  describe 'POST create' do
    context "not signed in" do
      before { post :create, entourage_id: entourage.to_param }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      context "first request to join entourage" do
        before { post :create, entourage_id: entourage.to_param, token: user.token, distance: 123.45 }
        it { expect(JoinRequest.last.distance).to eq(123.45) }
        it { expect(entourage.members).to eq([user]) }
        it { expect(result).to eq("user"=>{
                                            "id"=>user.id,
                                            "email"=>user.email,
                                            "display_name"=>"John D",
                                            "status"=>"pending",
                                            "message"=>nil,
                                            "requested_at"=>JoinRequest.last.created_at.iso8601(3),
                                            "avatar_url"=>nil,
                                            "partner"=>nil
                                          }) }
      end

      context "request to join entourage after a cancel" do
        before { JoinRequest.create(user: user, joinable: entourage, status: JoinRequest::CANCELLED_STATUS) }
        before { post :create, entourage_id: entourage.to_param, token: user.token }
        it { expect(entourage.members).to eq([user]) }
        it { expect(result).to eq("user"=>{
            "id"=>user.id,
            "email"=>user.email,
            "display_name"=>"John D",
            "status"=>"pending",
            "message"=>nil,
            "requested_at"=>JoinRequest.last.created_at.iso8601(3),
            "avatar_url"=>nil,
            "partner"=>nil
        }) }
      end

      context "duplicate request to join entourage" do
        before { JoinRequest.create(user: user, joinable: entourage) }
        before { post :create, entourage_id: entourage.to_param, token: user.token }
        it { expect(entourage.members).to eq([user]) }
        it { expect(result).to eq("user"=>{
            "id"=>user.id,
            "email"=>user.email,
            "display_name"=>"John D",
            "status"=>"pending",
            "message"=>nil,
            "requested_at"=>JoinRequest.last.created_at.iso8601(3),
            "avatar_url"=>nil,
            "partner"=>nil
        }) }
      end

      describe "push notif" do
        let!(:entourage_join_request) { JoinRequest.create(user: entourage.user, joinable: entourage, status: "accepted") }

        context "no join request message" do
          let!(:member) { FactoryGirl.create(:pro_user) }
          let!(:member_join_request) { JoinRequest.create(user: member, joinable: entourage, status: "accepted") }
          let!(:user_join_request) { JoinRequest.create(user: user, status: "accepted") }

          it "sends notif to all entourage members" do
            expect_any_instance_of(PushNotificationService).to receive(:send_notification).with("John D",
                                                                                                'Demande en attente',
                                                                                                "Un nouveau membre souhaite rejoindre votre entourage : foobar1",
                                                                                                [entourage.user],
                                                                                                {
                                                                                                    joinable_type: "Entourage",
                                                                                                    joinable_id: entourage.id,
                                                                                                    type: "NEW_JOIN_REQUEST",
                                                                                                    user_id: user.id
                                                                                                })
            post :create, entourage_id: entourage.to_param, token: user.token
          end
        end

        context "has join request message" do
          let!(:member) { FactoryGirl.create(:pro_user) }
          let!(:member_join_request) { JoinRequest.create(user: member, joinable: entourage, status: "accepted") }

          it "sends notif to all entourage members" do
            expect_any_instance_of(PushNotificationService).to receive(:send_notification).with("John D",
                                                                                                'Demande en attente',
                                                                                                "foobar",
                                                                                                [entourage.user],
                                                                                                {
                                                                                                    joinable_type: "Entourage",
                                                                                                    joinable_id: entourage.id,
                                                                                                    type: "NEW_JOIN_REQUEST",
                                                                                                    user_id: user.id
                                                                                                })
            post :create, { entourage_id: entourage.to_param, request: {message: "foobar"}, token: user.token}
          end
        end
      end
    end
  end

  describe "GET index" do
    context "not signed in" do
      before { get :index, entourage_id: entourage.to_param }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:join_request) { JoinRequest.create(user: user, joinable: entourage, status: "pending") }
      let!(:join_request1) { JoinRequest.create(user: user, joinable: entourage, status: "canceled") }
      let!(:join_request2) { JoinRequest.create(user: user, joinable: entourage, status: "rejected") }
      before { get :index, entourage_id: entourage.to_param, token: user.token }
      it { expect(result).to eq({"users"=>[{
                                               "id"=>user.id,
                                               "email"=>user.email,
                                               "display_name"=>"John D",
                                               "status"=>"pending",
                                               "message"=>nil,
                                               "requested_at"=>join_request.created_at.iso8601(3),
                                               "avatar_url"=>nil,
                                               "partner"=>nil
                                           }]}) }
    end
  end

  describe "PATCH update" do
    context "not signed in" do
      before { patch :update, entourage_id: entourage.to_param, id: user.id }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:join_request) { JoinRequest.create(user: user, joinable: entourage, status: "accepted") }

      context "valid params" do
        before { patch :update, entourage_id: entourage.to_param, id: user.id, user: {status: "accepted"}, token: user.token }
        it { expect(response.status).to eq(204) }
        it { expect(join_request.reload.status).to eq("accepted") }
      end
    end

    context "not accepted in tour" do
      let!(:join_request) { JoinRequest.create(user: user, joinable: entourage, status: "pending") }
      before { patch :update, entourage_id: entourage.to_param, id: user.id, user: {status: "accepted"}, token: user.token }
      it { expect(response.status).to eq(401) }
    end

    context "invalid status" do
      let!(:join_request) { JoinRequest.create(user: user, joinable: entourage, status: "accepted") }
      before { patch :update, entourage_id: entourage.to_param, id: user.id, user: {status: "foo"}, token: user.token }
      it { expect(response.status).to eq(400) }
      it { expect(result).to eq({"message"=>"Invalid status : foo"}) }
    end

    context "user didn't request to join entourage" do
      it "raises not found" do
        expect {
          patch :update, entourage_id: entourage.to_param, id: user.id, user: {status: "accepted"}, token: user.token
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "update my join request message" do
      let!(:join_request) { JoinRequest.create(user: user, joinable: entourage, message: nil) }
      before { patch :update, entourage_id: entourage.to_param, id: user.id, request: {message: "foobar"}, token: user.token }
      it { expect(response.status).to eq(204) }
      it { expect(join_request.reload.message).to eq("foobar") }
    end

    context "update someone else request message" do
      let(:other_user) { FactoryGirl.create(:pro_user) }
      let!(:other_join_request) { FactoryGirl.create(:join_request, user: other_user, joinable: entourage, status: "accepted") }
      let!(:join_request) { FactoryGirl.create(:join_request, user: user, joinable: entourage, message: "foobar") }
      before { patch :update, entourage_id: entourage.to_param, id: user.id, request: {message: "something"}, token: other_user.token }
      it { expect(response.status).to eq(401) }
    end
  end

  describe "DELETE destroy" do
    context "not signed in" do
      before { delete :destroy, entourage_id: entourage.to_param, id: user.id }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      context "reject someone from tour" do
        let!(:other_user) { FactoryGirl.create(:pro_user) }
        let!(:other_join_request) { JoinRequest.create(user: other_user, joinable: entourage, status: "accepted") }
        let!(:my_join_request) { JoinRequest.create(user: user, joinable: entourage, status: "accepted") }
        before { delete :destroy, entourage_id: entourage.to_param, id: other_user.id, token: user.token }
        it { expect(response.status).to eq(200) }
        it { expect(other_join_request.reload.status).to eq("rejected") }
        it { expect(my_join_request.reload.status).to eq("accepted") }
        it { expect(result).to eq({"user"=>{
                                            "id"=>other_user.id,
                                            "email"=>other_user.email,
                                            "display_name"=>"John D",
                                            "status"=>"rejected",
                                            "message"=>nil,
                                            "requested_at"=>other_join_request.created_at.iso8601(3),
                                            "avatar_url"=>nil,
                                            "partner"=>nil
                                          }
                                  }) }
      end

      context "quit tour" do
        let!(:my_join_request) { JoinRequest.create(user: user, joinable: entourage, status: "accepted") }
        before { delete :destroy, entourage_id: entourage.to_param, id: user.id, token: user.token }
        it { expect(response.status).to eq(200) }
        it { expect(expect(my_join_request.reload.status).to eq('cancelled')) }
        it { expect(result).to eq({"user"=>{
                                      "id"=>user.id,
                                      "email"=>user.email,
                                      "display_name"=>"John D",
                                      "status"=>"cancelled",
                                      "message"=>nil,
                                      "requested_at"=>my_join_request.created_at.iso8601(3),
                                      "avatar_url"=>nil,
                                      "partner"=>nil}
                                  }) }
      end
    end

    context "quit tour when join request is pending acceptance" do
      let!(:join_request) { JoinRequest.create(user: user, joinable: entourage, status: "pending") }
      before { delete :destroy, entourage_id: entourage.to_param, id: user.id, token: user.token }
      it { expect(response.status).to eq(200) }
    end

    context "reject someone from tour when join request is pending acceptance" do
      let!(:other_user) { FactoryGirl.create(:public_user) }
      let!(:my_join_request) { JoinRequest.create(user: user, joinable: entourage, status: "pending") }
      let!(:other_join_request) { JoinRequest.create(user: other_user, joinable: entourage, status: "pending") }
      before { delete :destroy, entourage_id: entourage.to_param, id: other_user.id, token: user.token }
      it { expect(response.status).to eq(401) }
    end

    context "user didn't request to join entourage" do
      it "raises not found" do
        expect {
          delete :destroy, entourage_id: entourage.to_param, id: user.id, token: user.token
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
