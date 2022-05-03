require 'rails_helper'

describe Api::V1::Neighborhoods::UsersController do

  let(:user) { FactoryBot.create(:public_user) }
  let(:neighborhood) { FactoryBot.create(:neighborhood, name: "foobar1") }
  let(:result) { JSON.parse(response.body) }

  describe "GET index" do
    context "not signed in" do
      before { get :index, params: { neighborhood_id: neighborhood.to_param } }
      it { expect(response.status).to eq(401) }
    end

    context "did not join neighborhood" do
      # we can see members even if we did not join
      before { get :index, params: { neighborhood_id: neighborhood.to_param, token: user.token } }
      it { expect(response.status).to eq(200) }
    end

    context "signed in" do
      let!(:join_request) { create(:join_request, user: user, joinable: neighborhood, status: :accepted) }
      let(:creator) { neighborhood.user }

      before { get :index, params: { neighborhood_id: neighborhood.to_param, token: user.token } }
      it { expect(result).to have_key("users") }
      it { expect(result["users"]).to match_array([{
        "id" => creator.id,
        "display_name" => "John D.",
        "role" => "creator",
        "group_role" => "creator",
        "community_roles" => [],
        "status" => "accepted",
        "message" => nil,
        "requested_at" => JoinRequest.where(user: creator, joinable: neighborhood).first.created_at.iso8601(3),
        "avatar_url" => nil,
        "partner" => nil,
        "partner_role_title" => nil,
      }, {
        "id" => user.id,
        "display_name" => "John D.",
        "role" => "member",
        "group_role" => "member",
        "community_roles" => [],
        "status" => "accepted",
        "message" => nil,
        "requested_at" => join_request.created_at.iso8601(3),
        "avatar_url" => nil,
        "partner" => nil,
        "partner_role_title" => nil,
      }]) }
    end
  end

  describe 'POST create' do
    context "not signed in" do
      before { post :create, params: { neighborhood_id: neighborhood.to_param } }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      context "first request to join neighborhood" do
        before { post :create, params: { neighborhood_id: neighborhood.to_param, token: user.token, distance: 123.45 } }
        it { expect(JoinRequest.last.distance).to eq(123.45) }
        it { expect(neighborhood.member_ids).to eq([neighborhood.user_id, user.id]) }
        it { expect(result).to eq(
          "user" => {
            "id" => user.id,
            "display_name" => "John D.",
            "role" => "member",
            "group_role" => "member",
            "community_roles" => [],
            "status" => "accepted",
            "message" => nil,
            "requested_at" => JoinRequest.last.created_at.iso8601(3),
            "avatar_url" => nil,
            "partner" => nil,
            "partner_role_title" => nil,
          }
        )}
      end

      context "duplicate request to join neighborhood" do
        let!(:join_request) { create(:join_request, user: user, joinable: neighborhood) }
        before { post :create, params: { neighborhood_id: neighborhood.to_param, token: user.token } }

        it { expect(neighborhood.member_ids).to match_array([neighborhood.user_id, user.id]) }
        it { expect(result).to eq(
          "user" => {
            "id" => user.id,
            "display_name" => "John D.",
            "role" => "member",
            "group_role" => join_request.role,
            "community_roles" => [],
            "status" => "accepted",
            "message" => nil,
            "requested_at" => JoinRequest.last.created_at.iso8601(3),
            "avatar_url" => nil,
            "partner" => nil,
            "partner_role_title" => nil,
          }
        )}
      end
    end
  end

  describe "DELETE destroy" do
    context "not signed in" do
      before { delete :destroy, params: { neighborhood_id: neighborhood.to_param, id: user.id } }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      context "quit neighborhood" do
        let!(:my_join_request) { create(:join_request, user: user, joinable: neighborhood, status: :accepted) }

        before { delete :destroy, params: { neighborhood_id: neighborhood.to_param, id: user.id, token: user.token } }
        it { expect(response.status).to eq(200) }
        it { expect(expect(my_join_request.reload.status).to eq('cancelled')) }
        it { expect(result).to eq({
          "user" => {
            "id" => user.id,
            "display_name" => "John D.",
            "role" => "member",
            "group_role" => "member",
            "community_roles" => [],
            "status" => "not_requested",
            "message" => nil,
            "requested_at" => my_join_request.created_at.iso8601(3),
            "avatar_url" => nil,
            "partner" => nil,
            "partner_role_title" => nil,
          }
        })}
      end

      context "can not quit another member" do
        let(:member) { FactoryBot.create(:public_user) }
        let!(:my_join_request) { create(:join_request, user: user, joinable: neighborhood, status: :accepted) }
        let!(:member_join_request) { create(:join_request, user: member, joinable: neighborhood, status: :accepted) }

        before { delete :destroy, params: { neighborhood_id: neighborhood.to_param, id: member.id, token: user.token } }

        it { expect(response.status).to eq(401) }
        it { expect(result).to have_key('message') }
      end

      context "user didn't request to join neighborhood" do
        before { delete :destroy, params: { neighborhood_id: neighborhood.to_param, id: user.id, token: user.token } }

        it { expect(response.status).to eq(401) }
        it { expect(result).to have_key('message') }
      end
    end
  end
end
