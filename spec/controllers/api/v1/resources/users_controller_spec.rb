require 'rails_helper'

describe Api::V1::Resources::UsersController do
  let(:user) { FactoryBot.create(:public_user) }
  let(:resource) { FactoryBot.create(:resource) }
  let(:result) { JSON.parse(response.body) }

  describe 'POST create' do
    let(:request) { post :create, params: { resource_id: resource.to_param, token: user.token } }
    let(:request_not_signed_in) { post :create, params: { resource_id: resource.to_param } }

    context "not signed in" do
      before { request_not_signed_in }

      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      context "users_resource created" do
        it { expect { request }.to change { UsersResource.count }.by(1) }
      end

      context "no users_resource" do
        let(:instance) { UsersResource.last }

        before { request }

        it { expect(instance.user_id).to eq(user.id) }
        it { expect(instance.resource_id).to eq(resource.id) }
        it { expect(instance.watched).to be(true) }

        it { expect(response.status).to eq(201) }
        it { expect(result).to eq(
          "users_resource" => {
            "user_id" => user.id,
            "resource_id" => resource.id,
            "watched" => true,
          }
        )}
      end
    end

    context "already not watched" do
      let!(:users_resource) { UsersResource.create(user_id: user.id, resource_id: resource.id, watched: false) }

      context "users_resource created" do
        it { expect { request }.to change { UsersResource.count }.by(0) }
      end

      context "no users_resource" do
        let(:instance) { UsersResource.last }

        before { request }

        it { expect(instance.user_id).to eq(user.id) }
        it { expect(instance.resource_id).to eq(resource.id) }
        it { expect(instance.watched).to be(true) }

        it { expect(response.status).to eq(201) }
        it { expect(result).to eq(
          "users_resource" => {
            "user_id" => user.id,
            "resource_id" => resource.id,
            "watched" => true,
          }
        )}
      end
    end
  end

  describe "DELETE destroy" do
    let!(:users_resource) { UsersResource.create(user_id: user.id, resource_id: resource.id, watched: true) }
    let(:subject) { users_resource.reload.watched }

    context "not signed in" do
      before { delete :destroy, params: { resource_id: resource.to_param, id: user.id } }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      context "unwatched resource" do
        before { delete :destroy, params: { resource_id: resource.to_param, id: user.id, token: user.token } }

        it { expect(response.status).to eq(201) }
        it { expect(expect(subject).to eq(false)) }
      end

      context "can not unwatched another member" do
        let(:member) { FactoryBot.create(:public_user) }
        let!(:member_join_request) { UsersResource.create(user_id: member.id, resource_id: resource.id, watched: true) }

        before { delete :destroy, params: { resource_id: resource.to_param, id: member.id, token: user.token } }

        it { expect(response.status).to eq(401) }
        it { expect(result).to have_key('message') }
      end

      context "user didn't watched resource" do
        before { users_resource.destroy }
        before { delete :destroy, params: { resource_id: resource.to_param, id: user.id, token: user.token } }

        it { expect(response.status).to eq(200) }
        it { expect(result).to eq('ok') }
      end
    end
  end

  describe "DELETE destroy on collection" do
    let!(:users_resource) { UsersResource.create(user_id: user.id, resource_id: resource.id, watched: true) }
    let(:subject) { users_resource.reload.watched }

    context "not signed in" do
      before { delete :destroy, params: { resource_id: resource.to_param } }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      context "quit resource" do
        before { delete :destroy, params: { resource_id: resource.to_param, token: user.token } }

        it { expect(response.status).to eq(201) }
        it { expect(expect(subject).to eq(false)) }
      end
    end
  end
end
