require 'rails_helper'

describe Api::V1::Conversations::UsersController do
  let(:user) { create(:public_user) }
  let(:creator) { create(:public_user) }

  let(:conversation) { create(:conversation, user: creator, participants: [creator]) }
  let(:result) { JSON.parse(response.body) }

  describe 'POST create' do
    context "not signed in" do
      before { post :create, params: { conversation_id: conversation.to_param } }

      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      context "first request to join conversation" do
        before { post :create, params: { conversation_id: conversation.uuid_v2, token: user.token } }

        it { expect(response.status).to eq(201) }
        it { expect(conversation.member_ids).to match_array([conversation.user_id, user.id]) }
        it { expect(result).to eq(
          "user" => {
            "id" => user.id,
            "display_name" => "John D.",
            "role" => "participant",
            "group_role" => "participant",
            "community_roles" => [],
            "status" => "accepted",
            "message" => nil,
            "confirmed_at" => nil,
            "requested_at" => JoinRequest.last.created_at.iso8601(3),
            "avatar_url" => nil,
            "partner" => nil,
            "partner_role_title" => nil,
          }
        )}
      end

      context "duplicate request to join conversation" do
        let!(:join_request) { create(:join_request, user: user, joinable: conversation, status: :cancelled) }
        before { post :create, params: { conversation_id: conversation.uuid_v2, token: user.token } }

        it { expect(conversation.member_ids).to match_array([conversation.user_id, user.id]) }
        it { expect(result).to eq(
          "user" => {
            "id" => user.id,
            "display_name" => "John D.",
            "role" => "participant",
            "group_role" => join_request.role,
            "community_roles" => [],
            "status" => "accepted",
            "message" => nil,
            "confirmed_at" => nil,
            "requested_at" => JoinRequest.last.created_at.iso8601(3),
            "avatar_url" => nil,
            "partner" => nil,
            "partner_role_title" => nil,
          }
        )}
      end
    end
  end

  describe 'POST invite' do
    context "not signed in" do
      before { post :invite, params: { conversation_id: conversation.to_param, id: user.id } }

      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      context "first request to join conversation" do
        before { post :invite, params: { conversation_id: conversation.uuid_v2, id: user.id, token: creator.token } }

        it { expect(response.status).to eq(201) }
        it { expect(conversation.member_ids).to match_array([conversation.user_id, user.id]) }
        it { expect(result).to eq(
          "user" => {
            "id" => user.id,
            "display_name" => "John D.",
            "role" => "participant",
            "group_role" => "participant",
            "community_roles" => [],
            "status" => "accepted",
            "message" => nil,
            "confirmed_at" => nil,
            "requested_at" => JoinRequest.last.created_at.iso8601(3),
            "avatar_url" => nil,
            "partner" => nil,
            "partner_role_title" => nil,
          }
        )}
      end

      context "duplicate request to join conversation" do
        let!(:join_request) { create(:join_request, user: user, joinable: conversation, status: :cancelled) }
        before { post :invite, params: { conversation_id: conversation.uuid_v2, id: user.id, token: creator.token } }

        it { expect(conversation.member_ids).to match_array([conversation.user_id, user.id]) }
        it { expect(result).to eq(
          "user" => {
            "id" => user.id,
            "display_name" => "John D.",
            "role" => "participant",
            "group_role" => join_request.role,
            "community_roles" => [],
            "status" => "accepted",
            "message" => nil,
            "confirmed_at" => nil,
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
      before { delete :destroy, params: { conversation_id: conversation.to_param } }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      context "quit conversation" do
        let!(:my_join_request) { create(:join_request, user: user, joinable: conversation, status: :accepted) }

        before { delete :destroy, params: { conversation_id: conversation.to_param, token: user.token } }
        it { expect(response.status).to eq(200) }
        it { expect(expect(my_join_request.reload.status).to eq('cancelled')) }
        it { expect(result).to eq({
          "user" => {
            "id" => user.id,
            "display_name" => "John D.",
            "role" => "participant",
            "group_role" => "participant",
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
