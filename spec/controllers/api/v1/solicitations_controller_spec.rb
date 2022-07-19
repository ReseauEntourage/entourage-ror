require 'rails_helper'

describe Api::V1::SolicitationsController, :type => :controller do
  render_views

  let(:user) { create :pro_user }

  context 'index' do
    let(:request) { get :index, params: { token: user.token } }
    subject { JSON.parse(response.body) }

    let(:latitude) { 48.85 }
    let(:longitude) { 2.27 }

    let(:solicitation) { FactoryBot.create(:solicitation, latitude: latitude, longitude: longitude) }
    let!(:join_request) { create(:join_request, user: solicitation.user, joinable: solicitation, status: :accepted, role: :member) }

    describe 'not authorized' do
      before { get :index }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(subject).to have_key('solicitations') }
    end

    describe 'do not get closed' do
      let!(:closed) { create :solicitation, status: :closed }

      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(subject).to have_key('solicitations') }
      it { expect(subject['solicitations'].count).to eq(1) }
      it { expect(subject['solicitations'][0]['id']).to eq(solicitation.id) }
    end

    context "some user is a member" do
      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject).to have_key("solicitations") }
      it { expect(subject["solicitations"].count).to eq(1) }
      it { expect(subject["solicitations"][0]).to have_key("members") }
      it { expect(subject["solicitations"][0]["members"]).to eq([{
        "id" => solicitation.user_id,
        "display_name" => "John D.",
        "avatar_url" => nil
      }]) }
    end

    context "some users are members" do
      let!(:join_request_1) { create(:join_request, user: FactoryBot.create(:public_user), joinable: solicitation, status: :accepted, role: :creator) }
      let!(:join_request_2) { create(:join_request, user: FactoryBot.create(:public_user), joinable: solicitation, status: :accepted, role: :creator) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject).to have_key("solicitations") }
      it { expect(subject["solicitations"].count).to eq(1) }
      it { expect(subject["solicitations"][0]).to have_key("members") }
      it { expect(subject["solicitations"][0]["members"].count).to eq(3) }
    end

    context "user being a member" do
      let!(:join_request) { create(:join_request, user: user, joinable: solicitation, status: :accepted, role: :creator) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["solicitations"].count).to eq(0) }
    end

    context "user being a member along with some users" do
      let!(:join_request) { create(:join_request, user: user, joinable: solicitation, status: :accepted, role: :creator) }
      let!(:join_request_1) { create(:join_request, user: FactoryBot.create(:public_user), joinable: solicitation, status: :accepted, role: :creator) }
      let!(:join_request_2) { create(:join_request, user: FactoryBot.create(:public_user), joinable: solicitation, status: :accepted, role: :creator) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["solicitations"].count).to eq(0) }
    end

    context "user being a member but not accepted" do
      let!(:join_request) { create(:join_request, user: user, joinable: solicitation, status: :pending, role: :creator) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["solicitations"].count).to eq(1) }
    end

    context "user not being a member" do
      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["solicitations"].count).to eq(1) }
    end

    context "params coordinates matches" do
      let(:request) { get :index, params: { token: user.token, latitude: 48.84, longitude: 2.28, travel_distance: 10 } }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["solicitations"].count).to eq(1) }
    end

    context "params coordinates do not matches" do
      let(:request) { get :index, params: { token: user.token, latitude: 47, longitude: 2, travel_distance: 1 } }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["solicitations"].count).to eq(0) }
    end

    context "user coordinates matches" do
      before { user.stub(:latitude) { 48.84 }}
      before { user.stub(:longitude) { 2.28 }}

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["solicitations"].count).to eq(1) }
    end

    context "user coordinates do not matches" do
      before { User.any_instance.stub(:latitude) { 40 } }
      before { User.any_instance.stub(:longitude) { 2 } }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["solicitations"].count).to eq(0) }
    end

    context "ordered by feed_updated_at desc" do
      let(:solicitation) { FactoryBot.create(:solicitation, feed_updated_at: 1.hour.from_now) }
      let(:solicitation_1) { FactoryBot.create(:solicitation, feed_updated_at: 1.day.from_now) }
      let!(:join_request_1) { create(:join_request, user: solicitation_1.user, joinable: solicitation_1, status: :accepted, role: :creator) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["solicitations"].count).to eq(2) }
      it { expect(subject["solicitations"][0]["id"]).to eq(solicitation_1.id) }
      it { expect(subject["solicitations"][1]["id"]).to eq(solicitation.id) }
    end
  end

  context 'create' do
    subject { JSON.parse(response.body) }
    let(:result) { Solicitation.find(subject['solicitation']['id']) }

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
      recipient_consent_obtained: true
    } }

    context "not signed in" do
      before { post :create, params: { solicitation: params } }
      it { expect(response.status).to eq(401) }
      it { expect(Solicitation.count).to eq(0) }
    end

    context "signed in" do
      context "without all required parameters" do
        before { post :create, params: { solicitation: {
          title: "foobar",
          longitude: 1.123,
          latitude: 4.567
        }, token: user.token } }

        it { expect(response.status).to eq(400) }
        it { expect(Solicitation.count).to eq(0) }
        it { expect(subject).to have_key("message") }
        it { expect(subject).to have_key("reasons") }
      end

      context "with all required parameters" do
        before { post :create, params: { solicitation: params, token: user.token } }

        it { expect(response.status).to eq(201) }
        it { expect(subject).to have_key("solicitation") }
        it { expect(Solicitation.count).to eq(1) }
        it { expect(Solicitation.last.metadata).to have_key(:city) }
        it { expect(result.group_type).to eq("action") }
        it { expect(result.entourage_type).to eq("ask_for_help") }
        it { expect(result.member_ids).to match_array([user.id]) }
        it { expect(result.moderation).to be_a(EntourageModeration) }
        it { expect(result.moderation.action_recipient_consent_obtained).to eq("Oui") }
      end
    end
  end

  describe 'GET show' do
    subject { JSON.parse(response.body) }

    let(:solicitation) { FactoryBot.create(:solicitation) }

    before { get :show, params: { token: user.token, id: solicitation.id } }

    it { expect(response.status).to eq 200 }
    it { expect(subject).to have_key("solicitation") }
    it { expect(subject["solicitation"]).to have_key("posts") }
  end
end
