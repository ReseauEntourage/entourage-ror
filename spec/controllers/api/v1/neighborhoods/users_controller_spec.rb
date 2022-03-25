require 'rails_helper'

describe Api::V1::Neighborhoods::UsersController do

  let(:user) { FactoryBot.create(:public_user) }
  let(:neighborhood) { FactoryBot.create(:neighborhood, name: "foobar1") }
  let(:result) { JSON.parse(response.body) }

  describe "GET index" do
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
        it { expect(neighborhood.members).to eq([user]) }
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

        it { expect(neighborhood.members).to eq([user]) }
        it { expect(result).to eq(
          "user" => {
            "id" => user.id,
            "display_name" => "John D.",
            "role" => "member",
            "group_role" => join_request.role,
            "community_roles" => [],
            "status" => join_request.status,
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
end
