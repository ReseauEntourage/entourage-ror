require 'rails_helper'
include CommunityHelper

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
                                            "display_name"=>"John D.",
                                            "role"=>"member",
                                            "group_role"=>"member",
                                            "community_roles"=>[],
                                            "status"=>"pending",
                                            "message"=>nil,
                                            "requested_at"=>JoinRequest.last.created_at.iso8601(3),
                                            "avatar_url"=>nil,
                                            "partner"=>nil,
                                            "partner_role_title"=>nil
                                          }) }
      end

      context "request to join entourage after a cancel" do
        before { create(:join_request, user: user, joinable: entourage, status: JoinRequest::CANCELLED_STATUS) }
        before { post :create, entourage_id: entourage.to_param, token: user.token }
        it { expect(entourage.members).to eq([user]) }
        it { expect(result).to eq("user"=>{
            "id"=>user.id,
            "display_name"=>"John D.",
            "status"=>"pending",
            "role"=>"member",
            "group_role"=>"member",
            "community_roles"=>[],
            "message"=>nil,
            "requested_at"=>JoinRequest.last.created_at.iso8601(3),
            "avatar_url"=>nil,
            "partner"=>nil,
            "partner_role_title"=>nil
        }) }
      end

      context "duplicate request to join entourage" do
        before { create(:join_request, user: user, joinable: entourage) }
        before { post :create, entourage_id: entourage.to_param, token: user.token }
        it { expect(entourage.members).to eq([user]) }
        it { expect(result).to eq("user"=>{
            "id"=>user.id,
            "display_name"=>"John D.",
            "role"=>"member",
            "group_role"=>"member",
            "community_roles"=>[],
            "status"=>"pending",
            "message"=>nil,
            "requested_at"=>JoinRequest.last.created_at.iso8601(3),
            "avatar_url"=>nil,
            "partner"=>nil,
            "partner_role_title"=>nil
        }) }
      end

      context "public group" do
        let(:entourage) { create :entourage, title: "foobar1", entourage_type: :contribution, public: true }
        let!(:creator_join_request) { create :join_request, user: entourage.user, joinable: entourage, status: "accepted" }
        let(:notif_service) { double }

        before do
          allow(notif_service).to receive(:send_notification)
          PushNotificationService.stub(:new) { notif_service }
        end

        context "first-time request" do
          before { post :create, entourage_id: entourage.to_param, token: user.token, distance: 123.45 }
          it { expect(result['user']['status']).to eq('accepted') }
          it {
            expect(notif_service).to have_received(:send_notification).with(
              "John D.",
              "foobar1",
              "John D. vient de rejoindre votre action",
              [entourage.user],
              {
                joinable_type: "Entourage",
                joinable_id: entourage.id,
                group_type: 'action',
                type: "JOIN_REQUEST_ACCEPTED",
                user_id: user.id
              }
            )
          }
        end

        context "after a cancel" do
          let!(:canceled_join_request) { create :join_request, user: user, joinable: entourage, status: "cancelled" }
          before { post :create, entourage_id: entourage.to_param, token: user.token, distance: 123.45 }
          it { pp result; expect(result['user']['status']).to eq('accepted') }
          it {
            expect(notif_service).to have_received(:send_notification).with(
              "John D.",
              "foobar1",
              "John D. vient de rejoindre votre action",
              [entourage.user],
              {
                joinable_type: "Entourage",
                joinable_id: entourage.id,
                group_type: 'action',
                type: "JOIN_REQUEST_ACCEPTED",
                user_id: user.id
              }
            )
          }
        end
      end

      describe "push notif" do
        let!(:entourage_join_request) { create(:join_request, user: entourage.user, joinable: entourage, status: "accepted") }

        context "no join request message" do
          let!(:member) { FactoryGirl.create(:pro_user) }
          let!(:member_join_request) { create(:join_request, user: member, joinable: entourage, status: "accepted") }
          let!(:user_join_request) { create(:join_request, user: user, status: "accepted") }

          it "sends notif to all entourage members" do
            expect_any_instance_of(PushNotificationService).to receive(:send_notification).with("John D.",
                                                                                                "foobar1",
                                                                                                "John D. souhaite rejoindre votre action",
                                                                                                [entourage.user],
                                                                                                {
                                                                                                    joinable_type: "Entourage",
                                                                                                    joinable_id: entourage.id,
                                                                                                    group_type: 'action',
                                                                                                    type: "NEW_JOIN_REQUEST",
                                                                                                    user_id: user.id
                                                                                                })
            post :create, entourage_id: entourage.to_param, token: user.token
          end
        end

        context "has join request message" do
          let!(:member) { FactoryGirl.create(:pro_user) }
          let!(:member_join_request) { create(:join_request, user: member, joinable: entourage, status: "accepted") }

          it "sends notif to all entourage members" do
            expect_any_instance_of(PushNotificationService).to receive(:send_notification).with("John D.",
                                                                                                "foobar1",
                                                                                                "John D. souhaite rejoindre votre action",
                                                                                                [entourage.user],
                                                                                                {
                                                                                                    joinable_type: "Entourage",
                                                                                                    joinable_id: entourage.id,
                                                                                                    group_type: 'action',
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
      let!(:join_request) { create(:join_request, user: user, joinable: entourage, status: "pending") }
      before { get :index, entourage_id: entourage.to_param, token: user.token }
      it { expect(result).to eq({"users"=>[{
                                               "id"=>user.id,
                                               "display_name"=>"John D.",
                                               "role"=>"member",
                                               "group_role"=>"member",
                                               "community_roles"=>[],
                                               "status"=>"pending",
                                               "message"=>nil,
                                               "requested_at"=>join_request.created_at.iso8601(3),
                                               "avatar_url"=>nil,
                                               "partner"=>nil,
                                               "partner_role_title"=>nil
                                           }]}) }
    end

    context "from a conversation" do
      let(:other_user) { create :public_user }
      let(:conversation) { create :conversation, participants: [user, other_user] }
      before { get :index, entourage_id: conversation.to_param, context: 'group_feed', token: user.token }
      it { expect(JSON.parse(response.body)).to eq("users" => []) }
    end

    context "from a null conversations by list uuid" do
      with_community :pfp
      let(:other_user) { create :public_user, first_name: "Buzz", last_name: "Lightyear" }
      before { get :index, entourage_id: "1_list_#{user.id}-#{other_user.id}", token: user.token }
      it { expect(JSON.parse(response.body)).to eq("users" => []) }
    end
  end

  describe "PATCH update" do
    context "not signed in" do
      before { patch :update, entourage_id: entourage.to_param, id: user.id }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:join_request) { create(:join_request, user: user, joinable: entourage, status: "accepted") }
      let(:requester) { FactoryGirl.create(:pro_user) }
      let!(:requester_join_request) { create(:join_request, user: requester, joinable: entourage, status: "pending") }

      context "valid params" do
        before { patch :update, entourage_id: entourage.to_param, id: user.id, user: {status: "accepted"}, token: user.token }
        it { expect(response.status).to eq(204) }
        it { expect(join_request.reload.status).to eq("accepted") }
      end

      it "sends a notification to the requester" do
        FactoryGirl.create(:android_app)
        expect_any_instance_of(PushNotificationService).to receive(:send_notification).with("John D.",
                                                                                            "foobar1",
                                                                                            "Vous venez de rejoindre l’action de John D.",
                                                                                            User.where(id: requester.id),
                                                                                            {:joinable_id=>entourage.id, :joinable_type=>"Entourage", :group_type=>'action', :type=>"JOIN_REQUEST_ACCEPTED", :user_id => requester.id})
        patch :update, entourage_id: entourage.to_param, id: requester.id, user: {status: "accepted"}, token: user.token
      end
    end

    context "not accepted in tour" do
      let!(:join_request) { create(:join_request, user: user, joinable: entourage, status: "pending") }
      before { patch :update, entourage_id: entourage.to_param, id: user.id, user: {status: "accepted"}, token: user.token }
      it { expect(response.status).to eq(401) }
    end

    context "invalid status" do
      let!(:join_request) { create(:join_request, user: user, joinable: entourage, status: "accepted") }
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
      let!(:join_request) { create(:join_request, user: user, joinable: entourage, message: nil) }
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
        let!(:other_join_request) { create(:join_request, user: other_user, joinable: entourage, status: "accepted") }
        let!(:my_join_request) { create(:join_request, user: user, joinable: entourage, status: "accepted") }
        before { delete :destroy, entourage_id: entourage.to_param, id: other_user.id, token: user.token }
        it { expect(response.status).to eq(200) }
        it { expect(other_join_request.reload.status).to eq("rejected") }
        it { expect(my_join_request.reload.status).to eq("accepted") }
        it { expect(result).to eq({"user"=>{
                                            "id"=>other_user.id,
                                            "display_name"=>"John D.",
                                            "role"=>"member",
                                            "group_role"=>"member",
                                            "community_roles"=>[],
                                            "status"=>"rejected",
                                            "message"=>nil,
                                            "requested_at"=>other_join_request.created_at.iso8601(3),
                                            "avatar_url"=>nil,
                                            "partner"=>nil,
                                            "partner_role_title"=>nil
                                          }
                                  }) }
      end

      context "quit tour" do
        let!(:my_join_request) { create(:join_request, user: user, joinable: entourage, status: "accepted") }
        before { delete :destroy, entourage_id: entourage.to_param, id: user.id, token: user.token }
        it { expect(response.status).to eq(200) }
        it { expect(expect(my_join_request.reload.status).to eq('cancelled')) }
        it { expect(result).to eq({"user"=>{
                                      "id"=>user.id,
                                      "display_name"=>"John D.",
                                      "role"=>"member",
                                      "group_role"=>"member",
                                      "community_roles"=>[],
                                      "status"=>"cancelled",
                                      "message"=>nil,
                                      "requested_at"=>my_join_request.created_at.iso8601(3),
                                      "avatar_url"=>nil,
                                      "partner"=>nil,
                                      "partner_role_title"=>nil}
                                  }) }
      end
    end

    context "quit tour when join request is pending acceptance" do
      let!(:join_request) { create(:join_request, user: user, joinable: entourage, status: "pending") }
      before { delete :destroy, entourage_id: entourage.to_param, id: user.id, token: user.token }
      it { expect(response.status).to eq(200) }
    end

    context "reject someone from tour when join request is pending acceptance" do
      let!(:other_user) { FactoryGirl.create(:public_user) }
      let!(:my_join_request) { create(:join_request, user: user, joinable: entourage, status: "pending") }
      let!(:other_join_request) { create(:join_request, user: other_user, joinable: entourage, status: "pending") }
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
