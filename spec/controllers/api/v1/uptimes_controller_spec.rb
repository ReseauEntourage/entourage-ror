require 'rails_helper'
include AuthHelper

RSpec.describe Api::V1::UptimesController, type: :controller do
  let(:user) { FactoryBot.create(:public_user) }
  let(:superadmin) { FactoryBot.create(:public_user, super_admin: true) }

  describe 'soliguides' do
    before {
      stub_request(:post, 'https://api.soliguide.fr/new-search').to_return(status: response_status, body: body, headers: {})
      get :soliguides, params: { token: token }
    }

    # default
    let(:token) { superadmin.token }
    let(:body) { '{"places":[{"test": "foo"}]}' }
    let(:response_status) { 200 }

    context 'default' do
      it { expect(response.status).to eq(200) }
      it { expect(response.body).to eq({ message: :ok, count: 1 }.to_json) }
    end

    context 'empty places' do
      let(:body) { '{"places":[]}' }

      it { expect(response.status).to eq(200) }
      it { expect(response.body).to eq({ message: :ok, count: 0 }.to_json) }
    end

    context 'unauthorized for not super-admin user' do
      let(:token) { user.token }

      it { expect(response.status).to eq(401) }
      it { expect(response.body).to eq({ message: :unauthorized }.to_json) }
    end

    context 'token unauthorized' do
      let(:response_status) { 401 }

      it { expect(response.status).to eq(401) }
      it { expect(response.body).to eq({ message: :bad_token }.to_json) }
    end

    context 'code validity bad_request' do
      let(:response_status) { :foo }

      it { expect(response.status).to eq(400) }
      it { expect(response.body).to eq({ message: :unexcepted_status }.to_json) }
    end

    context 'not_parsable' do
      let(:body) { 'foo' }

      it { expect(response.status).to eq(400) }
      it { expect(response.body).to eq({ message: :not_parsable }.to_json) }
    end

    context 'no places key' do
      let(:body) { '{"foo":[{}]}' }

      it { expect(response.status).to eq(400) }
      it { expect(response.body).to eq({ message: :no_places }.to_json) }
    end
  end

  describe 'soliguide' do
    before {
      stub_request(:get, 'https://api.soliguide.fr/place/0/fr').to_return(status: response_status, body: body, headers: {})
      get :soliguide, params: { token: token }
    }

    # default
    let(:token) { superadmin.token }
    let(:body) { '{"lieu_id": 0}' }
    let(:response_status) { 200 }

    context 'default' do
      it { expect(response.status).to eq(200) }
      it { expect(response.body).to eq({ message: :ok, lieu_id: 0 }.to_json) }
    end

    context 'unauthorized for not super-admin user' do
      let(:token) { user.token }

      it { expect(response.status).to eq(401) }
      it { expect(response.body).to eq({ message: :unauthorized }.to_json) }
    end

    context 'token unauthorized' do
      let(:response_status) { 401 }

      it { expect(response.status).to eq(401) }
      it { expect(response.body).to eq({ message: :bad_token }.to_json) }
    end

    context 'code validity bad_request' do
      let(:response_status) { :foo }

      it { expect(response.status).to eq(400) }
      it { expect(response.body).to eq({ message: :unexcepted_status }.to_json) }
    end

    context 'not_parsable' do
      let(:body) { 'foo' }

      it { expect(response.status).to eq(400) }
      it { expect(response.body).to eq({ message: :not_parsable }.to_json) }
    end

    context 'no place' do
      let(:body) { '{}' }

      it { expect(response.status).to eq(400) }
      it { expect(response.body).to eq({ message: :no_place }.to_json) }
    end
  end
end
