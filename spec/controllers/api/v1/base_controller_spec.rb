require 'rails_helper'

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
      let(:user) { FactoryGirl.create(:pro_user, last_sign_in_at: nil) }
      before { get :ping, {token: user.token} }
      it { expect(user.reload.last_sign_in_at).to_not be_nil }
    end

    context "last_sign_in_at yesterday" do
      let(:user) { FactoryGirl.create(:pro_user, last_sign_in_at: 1.day.ago) }
      before { get :ping, {token: user.token} }
      it { expect(user.reload.last_sign_in_at.today?).to be true}
    end

    context "last_sign_in_at yesterday" do
      let(:date) { DateTime.parse("2015-07-07T10:31:43.000+02:00") }
      before { Timecop.freeze(date) }
      let(:user) { FactoryGirl.create(:pro_user, last_sign_in_at: DateTime.parse("2014-07-07T00:00:00.000")) }
      before { get :ping, {token: user.token} }
      it { expect(user.reload.last_sign_in_at).to eq(date)}
    end

    context "last_sign_in_at today" do
      let(:date) { DateTime.parse("2015-07-07T10:31:43.000+02:00") }
      before { Timecop.freeze(date) }
      let(:user) { FactoryGirl.create(:pro_user, last_sign_in_at: DateTime.parse("2015-07-07T00:00:00.000")) }
      before { get :ping, {token: user.token} }
      it { expect(user.reload.last_sign_in_at).to eq(DateTime.parse("2015-07-07T00:00:00.000"))}
    end
  end
end