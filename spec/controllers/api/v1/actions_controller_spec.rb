require 'rails_helper'

describe Api::V1::ActionsController, :type => :controller do
  render_views

  let(:user) { create :pro_user }

  context 'index' do
    let(:request) { get :index, params: { token: user.token } }
    subject { JSON.parse(response.body) }

    let(:latitude) { 48.85 }
    let(:longitude) { 2.27 }

    let!(:action) { FactoryBot.create(:contribution, latitude: latitude, longitude: longitude) }

    describe 'not authorized' do
      before { get :index }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(subject).to have_key('actions') }
    end

    describe 'do not get closed' do
      let!(:action) { create :contribution, status: :closed }

      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(subject).to have_key('actions') }
      it { expect(subject['actions'].count).to eq(0) }
    end

    context "some user is a member" do
      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject).to have_key("actions") }
      it { expect(subject["actions"].count).to eq(1) }
      it { expect(subject["actions"][0]).to have_key("members") }
      it { expect(subject["actions"][0]["members"]).to eq([{
        "id" => action.user_id,
        "display_name" => "John D.",
        "avatar_url" => nil
      }]) }
    end

    context "some users are members" do
      let!(:join_request_1) { create(:join_request, user: FactoryBot.create(:public_user), joinable: action, status: :accepted, role: :member) }
      let!(:join_request_2) { create(:join_request, user: FactoryBot.create(:public_user), joinable: action, status: :accepted, role: :member) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject).to have_key("actions") }
      it { expect(subject["actions"].count).to eq(1) }
      it { expect(subject["actions"][0]).to have_key("members") }
      it { expect(subject["actions"][0]["members"].count).to eq(3) }
    end

    context "user being a member" do
      let!(:join_request) { create(:join_request, user: user, joinable: action, status: :accepted, role: :member) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["actions"].count).to eq(0) }
    end

    context "user being a member along with some users" do
      let!(:join_request) { create(:join_request, user: user, joinable: action, status: :accepted, role: :member) }
      let!(:join_request_1) { create(:join_request, user: FactoryBot.create(:public_user), joinable: action, status: :accepted, role: :member) }
      let!(:join_request_2) { create(:join_request, user: FactoryBot.create(:public_user), joinable: action, status: :accepted, role: :member) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["actions"].count).to eq(0) }
    end

    context "user not being a member" do
      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["actions"].count).to eq(1) }
    end

    context "params coordinates matches" do
      let(:request) { get :index, params: { token: user.token, latitude: 48.84, longitude: 2.28, travel_distance: 10 } }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["actions"].count).to eq(1) }
    end

    context "params coordinates do not matches" do
      let(:request) { get :index, params: { token: user.token, latitude: 47, longitude: 2, travel_distance: 1 } }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["actions"].count).to eq(0) }
    end

    context "user coordinates matches" do
      before { user.stub(:latitude) { 48.84 }}
      before { user.stub(:longitude) { 2.28 }}

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["actions"].count).to eq(1) }
    end

    context "user coordinates do not matches" do
      before { User.any_instance.stub(:latitude) { 40 } }
      before { User.any_instance.stub(:longitude) { 2 } }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["actions"].count).to eq(0) }
    end

    context "ordered by feed_updated_at desc" do
      let!(:action) { FactoryBot.create(:contribution, feed_updated_at: 1.hour.from_now) }
      let!(:action_1) { FactoryBot.create(:contribution, feed_updated_at: 1.day.from_now) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["actions"].count).to eq(2) }
      it { expect(subject["actions"][0]["id"]).to eq(action_1.id) }
      it { expect(subject["actions"][1]["id"]).to eq(action.id) }
    end
  end
end
