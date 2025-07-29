require 'rails_helper'

describe Api::V1::AnnouncementsController do
  let(:user) { FactoryBot.create(:offer_help_user) }
  let(:announcement) { FactoryBot.create(:announcement, user_goals: [:offer_help], areas: [:dep_75]) }

  describe 'GET index' do
    subject { JSON.parse(response.body) }

    context 'not signed in' do
      before { get :index }
      it { expect(response.status).to eq(401) }
    end

    context 'signed in' do
      before { get :index, params: { token: user.token } }

      it { expect(subject).to have_key('announcements') }
    end
  end

  describe 'GET icon' do
    before { get :icon, params: { id: announcement.id } }
    it { expect(response.status).to eq(302)}
    it { should redirect_to "http://test.host/assets/announcements/icons/#{announcement.icon}.png" }
  end

  describe 'GET redirect' do
    before { get :redirect, params: { id: announcement.id, token: user.token } }
    it { expect(response.status).to eq(302)}
    it { should redirect_to "#{announcement.url}?utm_source=app&utm_medium=announcement-card" }
  end
end
