require 'rails_helper'
include CommunityHelper

RSpec.describe Api::V1::BaseController, :type => :controller do
  render_views

  describe 'validate_request!' do
    before { Rails.env.stub(:test?) { false } }

    context "missing api key" do
      before { get :check }
      it { expect(response.status).to eq(426) }
    end

    context "invalid api key" do
      before { @request.env['X-API-KEY'] = 'foobar' }
      before { get :check }
      it { expect(response.status).to eq(426) }
    end

    context "valid api key" do
      before { @request.env['X-API-KEY'] = 'api_debug' }
      before { get :check }
      it { expect(response.status).to eq(200) }
    end
  end

  describe 'authenticate_user!' do
    context "nil last_sign_in_at" do
      let(:user) { FactoryBot.create(:pro_user, last_sign_in_at: nil) }
      before { get :ping, params: { token: user.token } }
      it { expect(user.reload.last_sign_in_at).to_not be_nil }
    end

    context "last_sign_in_at yesterday" do
      let(:user) { FactoryBot.create(:pro_user, last_sign_in_at: 1.day.ago) }
      before { get :ping, params: { token: user.token } }
      it { expect(user.reload.last_sign_in_at.today?).to be true}
    end

    context "last_sign_in_at yesterday" do
      let(:date) { DateTime.parse("2015-07-07T10:31:43.000+02:00") }
      before { Timecop.freeze(date) }
      let(:user) { FactoryBot.create(:pro_user, last_sign_in_at: DateTime.parse("2014-07-07T00:00:00.000")) }
      before { get :ping, params: { token: user.token } }
      it { expect(user.reload.last_sign_in_at).to eq(date)}
    end

    context "last_sign_in_at today" do
      let(:date) { DateTime.parse("2015-07-07T10:31:43.000+02:00") }
      before { Timecop.freeze(date) }
      let(:user) { FactoryBot.create(:pro_user, last_sign_in_at: DateTime.parse("2015-07-07T00:00:00.000")) }
      before { get :ping, params: { token: user.token } }
      it { expect(user.reload.last_sign_in_at).to eq(DateTime.parse("2015-07-07T00:00:00.000"))}
    end

    describe "session tracking" do
      before { SessionHistory.stub(:enable_tracking?) { true } }

      context "logged-in user" do
        let(:user) { create :public_user }
        before { get :ping, params: { token: user.token } }
        it { expect(SessionHistory.where(user_id: user.id, date: Time.zone.today, platform: 'rspec').count).to eq 1 }
      end
    end
  end

  describe 'ping_db' do
    let(:user) { FactoryBot.create(:pro_user) }

    before { get :ping_db, params: { token: user.token } }

    it { expect(response.status).to eq 200 }
    it { expect(JSON.parse(response.body)).to have_key 'count' }
  end

  describe 'ensure_community!' do
    before do
      @request.env['X-API-KEY'] = api_key
      allow(Rails.logger).to receive(:warn)
      get :check
    end
    subject { response.status }

    context "with a valid api key" do
      context "on the entourage server" do
        with_community :entourage
        let(:api_key) { 'api_debug' }
        it { is_expected.to eq(200) }
      end
    end

    context "with an api key for the wrong community" do
      context "on the entourage server" do
        with_community :entourage
        let(:api_key) { 'api_debug_pfp' }
        it { is_expected.to eq(401) }
      end
    end

    context "with an invalid api key" do
      let(:api_key) { 'foobar' }

      context "on the entourage server" do
        with_community :entourage
        it { is_expected.to eq(200) }
        it { expect(Rails.logger).to have_received(:warn).with(/code=no_api_key/) }
      end

      context "on the pfp server" do
        with_community :pfp
        it { is_expected.to eq(401) }
      end
    end

    context "with no api key" do
      let(:api_key) { '' }

      context "on the entourage server" do
        with_community :entourage
        it { is_expected.to eq(200) }
        it { expect(Rails.logger).to have_received(:warn).with(/code=no_api_key/) }
      end

      context "on the pfp server" do
        with_community :pfp
        it { is_expected.to eq(401) }
      end
    end
  end
end
