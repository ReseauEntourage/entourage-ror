require 'rails_helper'
include AuthHelper

RSpec.describe OrganizationController, :type => :controller do
  render_views
  
  context 'correct authentication' do
    let!(:user) { manager_basic_login }
    describe '#edit' do
      before { get :edit }
      it { should respond_with 200 }
    end
    describe '#update' do
      before { get :update, organization:{name: 'newname', description: 'newdescription', phone: 'newphone', address:'newaddress'} }
      it { expect(User.find(user.id).organization.name).to eq 'newname' }
      it { expect(User.find(user.id).organization.description).to eq 'newdescription' }
      it { expect(User.find(user.id).organization.phone).to eq 'newphone' }
      it { expect(User.find(user.id).organization.address).to eq 'newaddress' }
    end
    describe '#dashboard' do
      let!(:user1) { create :user }
      let!(:user2) { create :user }
      let!(:tour1) { create :tour, user: user1, updated_at: Time.now.monday }
      let!(:tour2) { create :tour, user: user1, updated_at: Time.now.monday }
      let!(:tour3) { create :tour, user: user2, updated_at: Time.now.monday }
      let!(:tour4) { create :tour, user: user2, updated_at: Time.now.monday - 1 }
      let!(:encounter1) { create :encounter, tour: tour1 }
      let!(:encounter2) { create :encounter, tour: tour1 }
      let!(:encounter3) { create :encounter, tour: tour2 }
      let!(:encounter4) { create :encounter, tour: tour3 }
      before { get :dashboard }
      it { should respond_with 200 }
      it { expect(assigns[:tour_count]).to eq 3 }
      it { expect(assigns[:tourer_count]).to eq 2 }
      it { expect(assigns[:encounter_count]).to eq 4 }
    end
  end
  context 'no authentication' do
    describe '#edit' do
      before { get :edit }
      it { should respond_with 401 }
    end
    describe '#update' do
      before { patch :update }
      it { should respond_with 401 }
    end
  end
end