require 'rails_helper'
include AuthHelper

RSpec.describe OrganizationsController, :type => :controller do
  render_views
  
  context 'correct authentication' do
    let!(:user) { manager_basic_login }
    describe 'edit' do
      before { get :edit, id: user.organization }
      it { should respond_with 200 }
    end
    describe '#update' do
      before { get :update, id: user.organization, organization:{name: 'newname', description: 'newdescription', phone: 'newphone', address:'newaddress'} }
      it { expect(User.find(user.id).organization.name).to eq 'newname' }
      it { expect(User.find(user.id).organization.description).to eq 'newdescription' }
      it { expect(User.find(user.id).organization.phone).to eq 'newphone' }
      it { expect(User.find(user.id).organization.address).to eq 'newaddress' }
    end

    describe 'GET statistics' do
      before { get :statistics }
      it { expect(response.status).to eq(200) }
    end

    describe '#dashboard' do
      let!(:time) { DateTime.new 2015, 8, 20, 0, 0, 0, '+2' }
      let!(:last_sunday) { (last_monday - 1).to_date }
      let!(:last_monday) { time.monday }
      let!(:last_tuesday) { (last_monday + 1).to_date }
      let!(:last_wednesday) { (last_monday + 2).to_date }
      let!(:user1) { create :user, organization: user.organization }
      let!(:user2) { create :user, organization: user.organization }
      let!(:tour1) { create :tour, user: user1, updated_at: time.monday + 1, length: 1001 }
      let!(:tour2) { create :tour, user: user1, updated_at: time.monday + 2, length: 2002 }
      let!(:tour3) { create :tour, user: user2, updated_at: time.monday + 2, length: 3003 }
      let!(:tour4) { create :tour, user: user2, updated_at: time.monday - 1, length: 2003 }
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
      it { expect(assigns[:total_length]).to eq 6006 }
      it { expect(assigns[:latest_tours][last_sunday]).to match_array([tour4]) }
      it { expect(assigns[:latest_tours][last_tuesday]).to match_array([tour1]) }
      it { expect(assigns[:latest_tours][last_wednesday]).to match_array([tour2, tour3]) }
    end
    describe 'tours' do
      let!(:time) { Time.new(2009, 3, 11, 8, 25, 00) }
      before do
        Timecop.freeze(time)
        user.coordinated_organizations << user4.organization
      end
      after { Timecop.return }
      let!(:user1) { create :user, organization: user.organization }
      let!(:user2) { create :user, organization: user.organization }
      let!(:user3) { create :user }
      let!(:user4) { create :user }
      let!(:tour1) { create :tour, user: user1, tour_type:'medical', updated_at: Time.new(2009, 3, 9, 13, 22, 0) }
      let!(:tour2) { create :tour, user: user2, tour_type:'alimentary', updated_at: Time.new(2009, 3, 11, 13, 22, 0) }
      let!(:tour3) { create :tour, user: user3 }
      let!(:tour4) { create :tour, user: user1, updated_at: Time.now.monday - 1 }
      let!(:tour5) { create :tour, user: user4, tour_type:'medical', updated_at: Time.new(2009, 3, 9, 13, 22, 0) }
      context 'with no filter' do
        before { get :tours, format: :json }
        it { should respond_with 200 }
        it { expect(assigns[:tours]).to match_array([tour1, tour2, tour5]) }
      end
      context 'with type filter' do
        before { get :tours, tour_type: 'alimentary', format: :json }
        it { should respond_with 200 }
        it { expect(assigns[:tours]).to eq [tour2]}
      end
      context 'with multiple type filter' do
        before { get :tours, tour_type: 'alimentary,medical', format: :json }
        it { expect(assigns[:tours]).to match_array([tour1, tour2, tour5])}
      end
      context 'with date range' do
        before { get :tours, date_range:'10/03/2009-11/03/2009', format: :json }
        it { should respond_with 200 }
        it { expect(assigns[:tours]).to eq [tour2]}
      end
      context 'with org filter' do
        before { get :tours, org:user4.organization.id, format: :json }
        it { should respond_with 200 }
        it { expect(assigns[:tours]).to eq [tour5]}
      end
      context 'with incorrect org filter' do
        before { get :tours, org:user3.organization.id, format: :json }
        it { should respond_with 200 }
        it { expect(assigns[:tours]).to eq []}
      end

      context "has map points" do
        before(:each) do
          [tour1, tour2, tour3].each do |t|
            FactoryGirl.create(:tour_point, tour: t, latitude: -35.2784167, longitude: 149.1294692)
            FactoryGirl.create(:tour_point, tour: t, latitude: -35.2847287248353, longitude: 149.128350617137)
          end
        end

        let(:resp) do
          get :tours, format: :json
          JSON.parse(response.body)
        end

        it { expect(resp["features"].count).to eq(3) }
        it "returns coordinates" do
          #some feature don't contain any coordinates => select the first feature containing coordinates
          feature = resp["features"].select {|hash| hash["geometry"]["coordinates"].present?}.first
          expect(feature["geometry"]["coordinates"]).to eq([[149.1294692, -35.2784167], [149.128350617137, -35.2847287248353]])
        end
      end
    end
    describe '#encounters' do
      let!(:time) { Time.new(2009, 3, 11, 8, 25, 00) }
      before do
        Timecop.freeze(time)
        user.coordinated_organizations << user4.organization
      end
      after { Timecop.return }
      let!(:user1) { create :user, organization: user.organization }
      let!(:user2) { create :user, organization: user.organization }
      let!(:user3) { create :user }
      let!(:user4) { create :user }
      let!(:tour1) { create :tour, user: user1, tour_type:'barehands', updated_at: Time.new(2009, 3, 9, 13, 22, 0) }
      let!(:tour2) { create :tour, user: user2, tour_type:'medical', updated_at: Time.new(2009, 3, 11, 13, 22, 0) }
      let!(:tour3) { create :tour, user: user3 }
      let!(:tour4) { create :tour, user: user1, updated_at: Time.now.monday - 1 }
      let!(:tour5) { create :tour, user: user4, tour_type:'barehands', updated_at: Time.new(2009, 3, 9, 13, 22, 0) }
      let!(:encounter1) { create :encounter, tour: tour1 }
      let!(:encounter2) { create :encounter, tour: tour1 }
      let!(:encounter3) { create :encounter, tour: tour2 }
      let!(:encounter4) { create :encounter, tour: tour2 }
      let!(:encounter5) { create :encounter, tour: tour3 }
      let!(:encounter6) { create :encounter, tour: tour4 }
      let!(:encounter7) { create :encounter, tour: tour5 }
      context 'with no filter' do
        before { get :encounters, format: :json }
        it { should respond_with 200 }
        it { expect(assigns[:encounters]).to eq [encounter1, encounter2, encounter3, encounter4, encounter7]}
        it { expect(assigns[:encounter_count]).to eq 5 }
        it { expect(assigns[:tourer_count]).to eq 3 }
        it { expect(assigns[:tour_count]).to eq 3 }
      end
      context 'with type filter' do
        before { get :encounters, tour_type: 'medical', format: :json }
        it { should respond_with 200 }
        it { expect(assigns[:encounters]).to eq [encounter3, encounter4]}
        it { expect(assigns[:encounter_count]).to eq 2 }
        it { expect(assigns[:tourer_count]).to eq 1 }
        it { expect(assigns[:tour_count]).to eq 1 }
      end
      context 'with date range' do
        before { get :encounters, date_range:'10/03/2009-11/03/2009', format: :json }
        it { should respond_with 200 }
        it { expect(assigns[:encounters]).to eq [encounter3, encounter4]}
        it { expect(assigns[:encounter_count]).to eq 2 }
        it { expect(assigns[:tourer_count]).to eq 1 }
        it { expect(assigns[:tour_count]).to eq 1 }
      end
      context 'with org filter' do
        before { get :encounters, org: user4.organization.id, format: :json }
        it { should respond_with 200 }
        it { expect(assigns[:encounters]).to eq [encounter7]}
        it { expect(assigns[:encounter_count]).to eq 1 }
        it { expect(assigns[:tourer_count]).to eq 1 }
        it { expect(assigns[:tour_count]).to eq 1 }
      end
      context 'with incorrect org filter' do
        before { get :encounters, org: user3.organization.id, format: :json }
        it { should respond_with 200 }
        it { expect(assigns[:encounters]).to eq []}
        it { expect(assigns[:encounter_count]).to eq 0 }
        it { expect(assigns[:tourer_count]).to eq 0 }
        it { expect(assigns[:tour_count]).to eq 0 }
      end
    end
    describe 'send_message' do
      let!(:user1) { create :user, organization: user.organization, device_type: :android, device_id:'deviceid1' }
      let!(:user2) { create :user, organization: user.organization, device_type: :android, device_id:nil }
      let!(:user3) { create :user, organization: user.organization, device_type: :android, device_id:'deviceid2' }
      let!(:user4) { create :user, organization: user.organization, device_type: nil, device_id:'deviceid3' }
      let!(:user5) { create :user }
      let!(:push_notification_service) { spy('push_notification_service') }
      before { controller.push_notification_service = push_notification_service }

      context "valid message" do
        before { post :send_message, id: user.organization.to_param, object:'object', message: 'message' }
        it { should respond_with 200 }
        it { expect(push_notification_service).to have_received(:send_notification).with(user.full_name, 'object', 'message', user.organization.users) }
      end
    end
  end
  context 'no authentication' do
    describe '#edit' do
      before { get :edit, id: 0  }
      it { should respond_with 302 }
    end
    describe '#update' do
      before { put :update, id: 0 }
      it { should respond_with 302 }
    end
    describe '#dashboard' do
      before { get :dashboard }
      it { should respond_with 302 }
    end
    describe '#tours' do
      before { get :tours, format: :json }
      it { should respond_with 302 }
    end
    describe '#encounters' do
      before { get :encounters, format: :json }
      it { should respond_with 302 }
    end
  end
end