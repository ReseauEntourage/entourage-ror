require 'rails_helper'

describe Api::V1::ContributionsController, :type => :controller do
  render_views

  let(:user) { create :pro_user }

  context 'index' do
    let(:request) { get :index, params: { token: user.token } }
    subject { JSON.parse(response.body) }

    let(:latitude) { 48.85 }
    let(:longitude) { 2.27 }

    let!(:contribution) { FactoryBot.create(:contribution, latitude: latitude, longitude: longitude) }

    describe 'not authorized' do
      before { get :index }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(subject).to have_key('contributions') }
    end

    describe 'do not get closed' do
      let!(:contribution) { create :contribution, status: :closed }

      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(subject).to have_key('contributions') }
      it { expect(subject['contributions'].count).to eq(0) }
    end

    context "some user is a member" do
      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject).to have_key("contributions") }
      it { expect(subject["contributions"].count).to eq(1) }
      it { expect(subject["contributions"][0]).to have_key("members") }
      it { expect(subject["contributions"][0]["members"]).to eq([{
        "id" => contribution.user_id,
        "display_name" => "John D.",
        "avatar_url" => nil
      }]) }
    end

    context "some users are members" do
      let!(:join_request_1) { create(:join_request, user: FactoryBot.create(:public_user), joinable: contribution, status: :accepted, role: :member) }
      let!(:join_request_2) { create(:join_request, user: FactoryBot.create(:public_user), joinable: contribution, status: :accepted, role: :member) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject).to have_key("contributions") }
      it { expect(subject["contributions"].count).to eq(1) }
      it { expect(subject["contributions"][0]).to have_key("members") }
      it { expect(subject["contributions"][0]["members"].count).to eq(3) }
    end

    context "user being a member" do
      let!(:join_request) { create(:join_request, user: user, joinable: contribution, status: :accepted, role: :member) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["contributions"].count).to eq(0) }
    end

    context "user being a member along with some users" do
      let!(:join_request) { create(:join_request, user: user, joinable: contribution, status: :accepted, role: :member) }
      let!(:join_request_1) { create(:join_request, user: FactoryBot.create(:public_user), joinable: contribution, status: :accepted, role: :member) }
      let!(:join_request_2) { create(:join_request, user: FactoryBot.create(:public_user), joinable: contribution, status: :accepted, role: :member) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["contributions"].count).to eq(0) }
    end

    context "user not being a member" do
      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["contributions"].count).to eq(1) }
    end

    context "params coordinates matches" do
      let(:request) { get :index, params: { token: user.token, latitude: 48.84, longitude: 2.28, travel_distance: 10 } }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["contributions"].count).to eq(1) }
    end

    context "params coordinates do not matches" do
      let(:request) { get :index, params: { token: user.token, latitude: 47, longitude: 2, travel_distance: 1 } }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["contributions"].count).to eq(0) }
    end

    context "user coordinates matches" do
      before { user.stub(:latitude) { 48.84 }}
      before { user.stub(:longitude) { 2.28 }}

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["contributions"].count).to eq(1) }
    end

    context "user coordinates do not matches" do
      before { User.any_instance.stub(:latitude) { 40 } }
      before { User.any_instance.stub(:longitude) { 2 } }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["contributions"].count).to eq(0) }
    end

    context "ordered by feed_updated_at desc" do
      let!(:contribution) { FactoryBot.create(:contribution, feed_updated_at: 1.hour.from_now) }
      let!(:contribution_1) { FactoryBot.create(:contribution, feed_updated_at: 1.day.from_now) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["contributions"].count).to eq(2) }
      it { expect(subject["contributions"][0]["id"]).to eq(contribution_1.id) }
      it { expect(subject["contributions"][1]["id"]).to eq(contribution.id) }
    end
  end

  context 'create' do
    subject { JSON.parse(response.body) }
    let(:result) { Contribution.find(subject['contribution']['id']) }

    let(:params) { {
      title: "Apéro Entourage",
      description: "Au Social Bar",
      metadata: {
        city: 'Nantes',
      },
      postal_code: '44000',
      location: {
        latitude: 48.85,
        longitude: 2.4,
      },
      section: 'clothes'
    } }

    context "not signed in" do
      before { post :create, params: { contribution: params } }
      it { expect(response.status).to eq(401) }
      it { expect(Contribution.count).to eq(0) }
    end

    context "signed in" do
      context "without all required parameters" do
        before { post :create, params: { contribution: {
          title: "foobar",
          longitude: 1.123,
          latitude: 4.567,
          section: "clothes"
        }, token: user.token } }

        it { expect(response.status).to eq(400) }
        it { expect(Contribution.count).to eq(0) }
        it { expect(subject).to have_key("message") }
        it { expect(subject).to have_key("reasons") }
      end

      context "with all required parameters" do
        before { post :create, params: { contribution: params, token: user.token } }

        it { expect(response.status).to eq(201) }
        it { expect(subject).to have_key("contribution") }
        it { expect(Contribution.count).to eq(1) }
        it { expect(result.section_list).to eq(['clothes']) }
        it { expect(result.metadata).to have_key(:city) }
        it { expect(result.group_type).to eq("action") }
        it { expect(result.entourage_type).to eq("contribution") }
        it { expect(result.member_ids).to match_array([user.id]) }
        it { expect(result.moderation).to be_nil }
      end
    end
  end

  describe 'PATCH update' do
    subject { JSON.parse(response.body) }

    let(:contribution) { FactoryBot.create(:contribution, status: :open) }

    context "not signed in" do
      before { patch :update, params: { id: contribution.to_param, contribution: { title: "new title" } } }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      context "user is not creator" do
        before { patch :update, params: { id: contribution.to_param, contribution: { title: "new title" }, token: user.token } }
        it { expect(response.status).to eq(401) }
      end

      context "user is creator" do
        let(:contribution) { FactoryBot.create(:contribution, :joined, user: user, status: :open) }

        before { patch :update, params: { id: contribution.to_param, contribution: { title: "New title" }, token: user.token } }

        it { expect(response.status).to eq(200) }
        it { expect(subject).to have_key('contribution') }
        it { expect(subject['contribution']['title']).to eq('New title') }
      end

      context "close" do
        let(:contribution) { FactoryBot.create(:contribution, :joined, user: user, status: :open) }

        before { patch :update, params: { id: contribution.to_param, contribution: { status: :closed }, token: user.token } }

        it { expect(response.status).to eq(200) }
        it { expect(subject).to have_key('contribution') }
        it { expect(subject['contribution']['status']).to eq('closed') }
        it { expect(contribution.reload.status).to eq('closed') }
      end
    end
  end

  describe 'GET show' do
    subject { JSON.parse(response.body) }

    let(:contribution) { FactoryBot.create(:contribution, section: "hygiene") }

    before { get :show, params: { token: user.token, id: contribution.id } }

    it { expect(response.status).to eq 200 }
    it { expect(subject).to have_key("contribution") }
    it { expect(subject["contribution"]).to have_key("posts") }
    it { expect(subject["contribution"]).to have_key("section") }
    it { expect(subject["contribution"]["section"]).to eq("hygiene") }
  end

  context 'destroy' do
    let(:creator) { create :pro_user }
    let(:contribution) { create :contribution, user: creator }

    let(:result) { Contribution.unscoped.find(contribution.id) }

    describe 'not authorized' do
      before { delete :destroy, params: { id: contribution.id } }

      it { expect(response.status).to eq 401 }
      it { expect(result.status).to eq 'open' }
    end

    describe 'not authorized cause should be creator' do
      before { delete :destroy, params: { id: contribution.id, token: user.token } }

      it { expect(response.status).to eq 401 }
      it { expect(result.status).to eq 'open' }
    end

    describe 'authorized' do
      let(:creator) { user }

      before { delete :destroy, params: { id: contribution.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result.status).to eq 'closed' }
    end
  end

  describe 'POST #presigned_upload' do
    let(:contribution) { FactoryBot.create(:contribution, status: :open) }

    let(:request) { post :presigned_upload, params: { id: contribution.to_param, token: token, content_type: 'image/jpeg' } }

    context "not signed in" do
      let(:token) { nil }

      before { request }

      it { expect(response.status).to eq(401) }
    end

    context "signed in but user is not creator" do
      let(:token) { user.token }

      before { request }

      it { expect(response.status).to eq(401) }
    end

    context "signed in and user is creator" do
      let(:token) { user.token }
      let(:contribution) { FactoryBot.create(:contribution, :joined, user: user, status: :open) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(JSON.parse(response.body)).to have_key('upload_key') }
      it { expect(JSON.parse(response.body)).to have_key('presigned_url') }
    end
  end
end
