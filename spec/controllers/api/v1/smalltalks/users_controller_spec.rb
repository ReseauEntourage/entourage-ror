require 'rails_helper'

describe Api::V1::Smalltalks::UsersController do
  let(:user) { create(:public_user) }
  let(:smalltalk) { create(:smalltalk) }
  let(:result) { JSON.parse(response.body) }

  describe "GET index" do
    context "not signed in" do
      before { get :index, params: { smalltalk_id: smalltalk.to_param } }
      it { expect(response.status).to eq(401) }
    end

    context "did not join smalltalk" do
      # we can see members even if we did not join
      before { get :index, params: { smalltalk_id: smalltalk.to_param, token: user.token } }
      it { expect(response.status).to eq(200) }
    end

    context "signed in" do
      let!(:join_request) { create(:join_request, user: user, joinable: smalltalk, status: :accepted) }

      before { get :index, params: { smalltalk_id: smalltalk.to_param, token: user.token } }
      it { expect(result).to have_key("users") }
      it { expect(result["users"]).to match_array([{
        "id" => user.id,
        "uuid" => user.reload.uuid,
        "display_name" => "John D.",
        "role" => "member",
        "group_role" => "member",
        "community_roles" => [],
        "status" => "accepted",
        "message" => nil,
        "confirmed_at" => nil,
        "requested_at" => join_request.created_at.iso8601(3),
        "avatar_url" => nil,
        "partner" => nil,
        "partner_role_title" => nil,
      }]) }
    end
  end

  describe "DELETE destroy on collection" do
    context "not signed in" do
      before { delete :destroy, params: { smalltalk_id: smalltalk.to_param } }
      it { expect(response.status).to eq(401) }
    end


    context "signed in" do
      context "quit smalltalk" do
        let!(:my_join_request) { create(:join_request, user: user, joinable: smalltalk, status: :accepted) }

        before { delete :destroy, params: { smalltalk_id: smalltalk.to_param, token: user.token } }
        it { expect(response.status).to eq(200) }
        it { expect(expect(my_join_request.reload.status).to eq('cancelled')) }
        it { expect(result).to eq({
          "user" => {
            "id" => user.id,
            "uuid" => user.reload.uuid,
            "display_name" => "John D.",
            "role" => "member",
            "group_role" => "member",
            "community_roles" => [],
            "status" => "not_requested",
            "message" => nil,
            "confirmed_at" => nil,
            "requested_at" => my_join_request.created_at.iso8601(3),
            "avatar_url" => nil,
            "partner" => nil,
            "partner_role_title" => nil,
          }
        })}
      end
    end
  end
end
