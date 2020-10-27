require 'rails_helper'

describe Api::V1::Tours::UsersController do
  let(:user) { FactoryGirl.create(:pro_user) }
  let(:tour) { FactoryGirl.create(:tour) }
  let(:result) { JSON.parse(response.body) }

  describe 'POST create' do
    context "not signed in" do
      before { post :create, tour_id: tour.to_param }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      context "first request to join tour" do
        before { post :create, tour_id: tour.to_param, token: user.token }
        it { expect(tour.members).to eq([user]) }
        it { expect(result).to eq("user"=>{"id"=>user.id,
                                                              "display_name"=>"John D.",
                                                              "role"=>"member",
                                                              "group_role"=>"member",
                                                              "community_roles"=>[],
                                                              "status" => "pending",
                                                              "message"=>nil,
                                                              "avatar_url"=>nil,
                                                              "requested_at"=>JoinRequest.last.created_at.iso8601(3),
                                                              "partner"=>nil,
                                                              "partner_role_title"=>nil}) }
        it { expect(tour.reload.number_of_people).to eq(1) }
      end

      context "duplicate request to join tour" do
        let(:tour) { create :tour }
        before { create(:join_request, user: user, joinable: tour) }
        before { post :create, tour_id: tour.to_param, token: user.token }
        it { expect(tour.members).to eq([user]) }
        it { expect(result).to eq("user"=>{"id"=>user.id,
                                           "display_name"=>"John D.",
                                           "role"=>"member",
                                           "group_role"=>"member",
                                           "community_roles"=>[],
                                           "status" => "pending",
                                           "message"=>nil,
                                           "avatar_url"=>nil,
                                           "requested_at"=>JoinRequest.last.created_at.iso8601(3),
                                           "partner"=>nil,
                                           "partner_role_title"=>nil}) }
        it { expect(tour.reload.number_of_people).to eq(0) }
      end

      it "sends a notifications to tour owner" do
        new_member = FactoryGirl.create(:pro_user)
        create(:join_request, user: user, joinable: tour, status: "accepted")
        expect_any_instance_of(PushNotificationService).to receive(:send_notification).with("John D.",
                                                                                            "Demande en attente",
                                                                                            "John D. souhaite rejoindre votre maraude",
                                                                                            [tour.user],
                                                                                            {:joinable_id=>tour.id, :joinable_type=>"Tour", :group_type=>'tour', :type=>"NEW_JOIN_REQUEST", :user_id => new_member.id}
        )
        post :create, tour_id: tour.to_param, token: new_member.token
      end

      context "with message" do
        before { post :create, tour_id: tour.to_param, request: {message: "foo"}, token: user.token }
        it { expect(tour.members).to eq([user]) }
        it { expect(result).to eq("user"=>{"id"=>user.id,
                                                              "display_name"=>"John D.",
                                                              "status" => "pending",
                                                              "role"=>"member",
                                                              "group_role"=>"member",
                                                              "community_roles"=>[],
                                                              "message"=> "foo",
                                                              "requested_at"=>JoinRequest.last.created_at.iso8601(3),
                                                              "avatar_url"=>nil,
                                                              "partner"=>nil,
                                                              "partner_role_title"=>nil}) }
      end
    end
  end

  describe "GET index" do
    context "not signed in" do
      before { get :index, tour_id: tour.to_param }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:join_request) { FactoryGirl.create(:join_request, user: user, joinable: tour) }
      before { get :index, tour_id: tour.to_param, token: user.token }
      it { expect(result).to eq({"users"=>[{"id"=>user.id,
                                                               "display_name"=>"John D.",
                                                               "status"=>"pending",
                                                               "role"=>"member",
                                                               "group_role"=>"member",
                                                               "community_roles"=>[],
                                                               "message"=>nil,
                                                               "requested_at"=>join_request.created_at.iso8601(3),
                                                               "avatar_url"=>nil,
                                                               "partner"=>nil,
                                                               "partner_role_title"=>nil}]}) }
    end
  end

  describe "PATCH update" do
    context "not signed in" do
      before { patch :update, tour_id: tour.to_param, id: user.id }
      it { expect(response.status).to eq(401) }
    end

    context "signed in as accepted member of the tour" do
      let(:requester) { FactoryGirl.create(:pro_user) }
      let!(:tour_member) { create(:join_request, user: user, joinable: tour, status: "accepted") }
      let!(:tour_requester) { create(:join_request, user: requester, joinable: tour, status: "pending") }

      context "valid params" do
        before { FactoryGirl.create(:android_app) }
        before { patch :update, tour_id: tour.to_param, id: requester.id, user: {status: "accepted"}, token: user.token }
        it { expect(response.status).to eq(204) }
        it { expect(tour_requester.reload.status).to eq("accepted") }
      end

      it "sends a notification to the requester" do
        FactoryGirl.create(:android_app)
        expect_any_instance_of(PushNotificationService).to receive(:send_notification).with("John D.",
                                                                                            "Demande acceptée",
                                                                                            "Vous venez de rejoindre la maraude de John D.",
                                                                                            User.where(id: requester.id),
                                                                                            {:joinable_id=>tour.id, :joinable_type=>"Tour", :group_type => 'tour', :type=>"JOIN_REQUEST_ACCEPTED", :user_id => requester.id})
        patch :update, tour_id: tour.to_param, id: requester.id, user: {status: "accepted"}, token: user.token
      end

      context "invalid status" do
        before { patch :update, tour_id: tour.to_param, id: requester.id, user: {status: "foobar"}, token: user.token }
        it { expect(response.status).to eq(400) }
        it { expect(tour_requester.reload.status).to eq("pending") }
      end

      context "invalid params" do
        before { patch :update, tour_id: tour.to_param, id: requester.id, status: "foobar", token: user.token }
        it { expect(response.status).to eq(400) }
        it { expect(tour_requester.reload.status).to eq("pending") }
      end
    end

    context "not member of the tour" do
      let(:requester) { FactoryGirl.create(:pro_user) }
      let!(:other_tour_member) { create(:join_request, user: user, joinable: FactoryGirl.create(:tour), status: "accepted") }
      let!(:tour_requested) { create(:join_request, user: requester, joinable: tour, status: "pending") }
      before { patch :update, tour_id: tour.to_param, id: requester.id, user: {status: "accepted"}, token: user.token }
      it { expect(response.status).to eq(401) }
      it { expect(tour_requested.reload.status).to eq("pending") }
    end

    context "member of the tour but not accepted" do
      let(:requester) { FactoryGirl.create(:pro_user) }
      let!(:tour_member) { create(:join_request, user: user, joinable: tour, status: "pending") }
      let!(:tour_requested) { create(:join_request, user: requester, joinable: tour, status: "pending") }
      before { patch :update, tour_id: tour.to_param, id: requester.id, user: {status: "accepted"}, token: user.token }
      it { expect(response.status).to eq(401) }
      it { expect(tour_requested.reload.status).to eq("pending") }
    end

    context "user didn't request to join tour" do
      it "raises not found" do
        expect {
          patch :update, tour_id: tour.to_param, id: user.id, user: {status: "accepted"}, token: user.token
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "DELETE destroy" do
    context "not signed in" do
      before { delete :destroy, tour_id: tour.to_param, id: user.id }
      it { expect(response.status).to eq(401) }
    end

    context "signed in as accepted member of the tour" do
      let(:requester) { FactoryGirl.create(:pro_user) }
      let!(:tour_member) { create(:join_request, user: user, joinable: tour, status: "accepted") }
      let!(:tour_requested) { create(:join_request, user: requester, joinable: tour, status: "pending") }
      before { delete :destroy, tour_id: tour.to_param, id: requester.id, token: user.token }
      it { expect(response.status).to eq(200) }
      it { expect(result).to eq({"user"=>{
                                          "id"=>requester.id,
                                          "display_name"=>"John D.",
                                          "role"=>"member",
                                          "group_role"=>"member",
                                          "community_roles"=>[],
                                          "status"=>"rejected",
                                          "message"=>nil,
                                          "requested_at"=>JoinRequest.last.created_at.iso8601(3),
                                          "avatar_url"=>nil,
                                          "partner"=>nil,
                                          "partner_role_title"=>nil
                                          }}) }
      it { expect(tour_requested.reload.status).to eq("rejected") }
      it { expect(tour.reload.number_of_people).to eq(1) }

      context "delete the same user twice" do
        before { delete :destroy, tour_id: tour.to_param, id: requester.id, token: user.token }
        it { expect(response.status).to eq(200) }
        it { expect(tour.reload.number_of_people).to eq(1) }
      end
    end

    context "delete yourself" do
      let!(:tour_member) { create(:join_request, user: user, joinable: tour, status: "accepted") }
      before { delete :destroy, tour_id: tour.to_param, id: user.id, token: user.token }
      it { expect(response.status).to eq(200) }
      it { expect(result).to eq({"user"=>{
                                  "id"=>user.id,
                                  "display_name"=>"John D.",
                                  "role"=>"member",
                                  "group_role"=>"member",
                                  "community_roles"=>[],
                                  "status"=>"cancelled",
                                  "message"=>nil,
                                  "requested_at"=>tour_member.created_at.iso8601(3),
                                  "avatar_url"=>nil,
                                  "partner"=>nil,
                                  "partner_role_title"=>nil}
                                }) }
      it { expect(tour.reload.number_of_people).to eq(0) }
    end

    context "delete the author of the tour" do
      let!(:tour_author) { create(:join_request, user: tour.user, joinable: tour, status: "accepted") }
      let!(:tour_member) { create(:join_request, user: user, joinable: tour, status: "accepted") }
      before { delete :destroy, tour_id: tour.to_param, id: tour.user.id, token: user.token }
      it { expect(response.status).to eq(400) }
      it { expect(tour.reload.number_of_people).to eq(2) }
    end

    context "not member of the tour" do
      let(:requester) { FactoryGirl.create(:pro_user) }
      let!(:other_tour_member) { create(:join_request, user: user, joinable: FactoryGirl.create(:tour), status: "accepted") }
      let!(:tour_requested) { create(:join_request, user: requester, joinable: tour, status: "pending") }
      before { delete :destroy, tour_id: tour.to_param, id: requester.id, token: user.token }
      it { expect(response.status).to eq(401) }
      it { expect(tour_requested.reload.status).to eq("pending") }
    end

    context "member of the tour but not accepted" do
      let(:requester) { FactoryGirl.create(:pro_user) }
      let!(:tour_member) { create(:join_request, user: user, joinable: tour, status: "pending") }
      let!(:tour_requested) { create(:join_request, user: requester, joinable: tour, status: "pending") }
      before { delete :destroy, tour_id: tour.to_param, id: requester.id, token: user.token }
      it { expect(response.status).to eq(401) }
      it { expect(tour_requested.reload.status).to eq("pending") }
    end

    context "user didn't request to join tour" do
      it "raises not found" do
        expect {
          delete :destroy, tour_id: tour.to_param, id: user.id, token: user.token
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
