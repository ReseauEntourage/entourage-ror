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
      let!(:time) { DateTime.new 2015, 8, 20, 0, 0, 0, '+2' }
      let!(:last_sunday) { (last_monday - 1).to_date }
      let!(:last_monday) { time.monday }
      let!(:last_tuesday) { (last_monday + 1).to_date }
      let!(:last_wednesday) { (last_monday + 2).to_date }
      let!(:user1) { create :user, organization: user.organization }
      let!(:user2) { create :user, organization: user.organization }
      let!(:tour1) { create :tour, user: user1, updated_at: time.monday + 1 }
      let!(:tour2) { create :tour, user: user1, updated_at: time.monday + 2 }
      let!(:tour3) { create :tour, user: user2, updated_at: time.monday + 2 }
      let!(:tour4) { create :tour, user: user2, updated_at: time.monday - 1 }
      let!(:encounter1) { create :encounter, tour: tour1 }
      let!(:encounter2) { create :encounter, tour: tour1 }
      let!(:encounter3) { create :encounter, tour: tour2 }
      let!(:encounter4) { create :encounter, tour: tour3 }
      before do
        Timecop.freeze(time)
        get :dashboard
      end
      after { Timecop.return }
      it { should respond_with 200 }
      it { expect(assigns[:tour_count]).to eq 3 }
      it { expect(assigns[:tourer_count]).to eq 2 }
      it { expect(assigns[:encounter_count]).to eq 4 }
      it { expect(assigns[:latest_tours]).to eq({ last_sunday => [tour4], last_tuesday => [tour1], last_wednesday => [tour2, tour3] }) }
    end
    describe '#tours' do
      let!(:user1) { create :user, organization: user.organization }
      let!(:user2) { create :user, organization: user.organization }
      let!(:user3) { create :user }
      let!(:tour1) { create :tour, user: user1, tour_type:'other' }
      let!(:tour2) { create :tour, user: user2, tour_type:'health' }
      let!(:tour3) { create :tour, user: user3 }
      let!(:tour4) { create :tour, user: user1, updated_at: Time.now.monday - 1 }
      context 'with no filter' do
        before { get :tours, format: :json }
        it { should respond_with 200 }
        it { expect(assigns[:tours]).to eq [tour1, tour2]}
      end
      context 'with type filter' do
        before { get :tours, tour_type: 'health', format: :json }
        it { should respond_with 200 }
        it { expect(assigns[:tours]).to eq [tour2]}
      end
    end
    describe '#encounters' do
      let!(:user1) { create :user, organization: user.organization }
      let!(:user2) { create :user, organization: user.organization }
      let!(:user3) { create :user }
      let!(:tour1) { create :tour, user: user1, tour_type:'other' }
      let!(:tour2) { create :tour, user: user2, tour_type:'health' }
      let!(:tour3) { create :tour, user: user3 }
      let!(:tour4) { create :tour, user: user1, updated_at: Time.now.monday - 1 }
      let!(:encounter1) { create :encounter, tour: tour1 }
      let!(:encounter2) { create :encounter, tour: tour1 }
      let!(:encounter3) { create :encounter, tour: tour2 }
      let!(:encounter4) { create :encounter, tour: tour2 }
      let!(:encounter5) { create :encounter, tour: tour3 }
      let!(:encounter6) { create :encounter, tour: tour4 }
      context 'with no filter' do
        before { get :encounters, format: :json }
        it { should respond_with 200 }
        it { expect(assigns[:encounters]).to eq [encounter1, encounter2, encounter3, encounter4]}
      end
      context 'with type filter' do
        before { get :encounters, tour_type: 'health', format: :json }
        it { should respond_with 200 }
        it { expect(assigns[:encounters]).to eq [encounter3, encounter4]}
      end
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
    describe '#dashboard' do
      before { get :dashboard }
      it { should respond_with 401 }
    end
    describe '#tours' do
      before { get :tours, format: :json }
      it { should respond_with 401 }
    end
    describe '#encounters' do
      before { get :encounters, format: :json }
      it { should respond_with 401 }
    end
  end
end