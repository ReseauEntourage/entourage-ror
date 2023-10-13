require 'rails_helper'
include AuthHelper

RSpec.describe OrganizationsController, :type => :controller do
  render_views

  context 'correct authentication' do
    let!(:user) { manager_basic_login }
    describe 'edit' do
      before { get :edit, params: { id: user.organization } }
      it { expect(response.status).to eq(200) }
    end
    describe '#update' do
      before { get :update, params: { id: user.organization, organization:{name: 'newname', description: 'newdescription', phone: 'newphone', address:'newaddress'} } }
      it { expect(User.find(user.id).organization.name).to eq 'newname' }
      it { expect(User.find(user.id).organization.description).to eq 'newdescription' }
      it { expect(User.find(user.id).organization.phone).to eq 'newphone' }
      it { expect(User.find(user.id).organization.address).to eq 'newaddress' }
    end

    describe 'GET statistics' do
      before { get :statistics }
      #TODO : disable statistics
      #it { expect(response.status).to eq(200) }
    end

    describe 'dashboard' do
      let!(:time) { DateTime.new 2015, 8, 20, 0, 0, 0, '+2' }
      let!(:last_sunday) { (last_monday - 1).to_date }
      let!(:last_monday) { time.monday }
      let!(:last_tuesday) { (last_monday + 1).to_date }
      let!(:last_wednesday) { (last_monday + 2).to_date }
      let!(:user1) { create :pro_user, organization: user.organization }
      let!(:user2) { create :pro_user, organization: user.organization }
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
      it { expect(response.status).to eq(200) }
      it { expect(assigns(:tours_presenter).week_tours.count).to eq 3 }
      it { expect(assigns(:tours_presenter).tourer_count).to eq 2 }
      it { expect(assigns(:tours_presenter).encounter_count).to eq 4 }
      it { expect(assigns(:tours_presenter).total_length).to eq "6,006 km" }
      it { expect(assigns(:tours_presenter).latest_tours.find { |collection_cache, day, tour| day == last_sunday    }[2]).to match_array([tour4]) }
      it { expect(assigns(:tours_presenter).latest_tours.find { |collection_cache, day, tour| day == last_tuesday   }[2]).to match_array([tour1]) }
      it { expect(assigns(:tours_presenter).latest_tours.find { |collection_cache, day, tour| day == last_wednesday }[2]).to match_array([tour2, tour3]) }
    end
    describe 'tours' do
      let!(:time) { Time.new(2009, 3, 11, 8, 25, 00) }
      before do
        Timecop.freeze(time)
        user.coordinated_organizations << user4.organization
      end
      let!(:user1) { create :pro_user, organization: user.organization }
      let!(:user2) { create :pro_user, organization: user.organization }
      let!(:user3) { create :pro_user }
      let!(:user4) { create :pro_user }
      let!(:tour1) { create :tour, user: user1, tour_type:'medical', updated_at: Time.new(2009, 3, 9, 13, 22, 0) }
      let!(:tour2) { create :tour, user: user2, tour_type:'alimentary', updated_at: Time.new(2009, 3, 11, 13, 22, 0) }
      let!(:tour3) { create :tour, user: user3 }
      let!(:tour4) { create :tour, user: user1, updated_at: Time.now.monday - 1 }
      let!(:tour5) { create :tour, user: user4, tour_type:'medical', updated_at: Time.new(2009, 3, 9, 13, 22, 0) }
      context 'with no filter' do
        before { get :tours, format: :json }
        it { expect(response.status).to eq(200) }
        it { expect(assigns[:tours].map(&:id)).to match_array([tour1, tour2, tour5].map(&:id)) }
      end
      context 'with type filter' do
        before { get :tours, params: { tour_type: 'alimentary', format: :json } }
        it { expect(response.status).to eq(200) }
        it { expect(assigns[:tours]).to eq [tour2]}
      end
      context 'with multiple type filter' do
        before { get :tours, params: { tour_type: 'alimentary,medical', format: :json } }
        it { expect(assigns[:tours]).to match_array([tour1, tour2, tour5])}
      end
      context 'with date range' do
        before { get :tours, params: { date_range:'10/03/2009-11/03/2009', format: :json } }
        it { expect(response.status).to eq(200) }
        it { expect(assigns[:tours]).to eq [tour2]}
      end
      context 'with org filter' do
        before { get :tours, params: { org:user4.organization.id, format: :json } }
        it { expect(response.status).to eq(200) }
        it { expect(assigns[:tours]).to eq [tour5]}
      end
      context 'with incorrect org filter' do
        before { get :tours, params: { org:user3.organization.id, format: :json } }
        it { expect(response.status).to eq(200) }
        it { expect(assigns[:tours]).to eq []}
      end
      context 'with valid box filter' do
        before { get :tours, params: { sw:"48.615629449762814_1.8729114532470703", ne:"49.24715808228131_2.8177356719970703", format: :json } }
        it { expect(response.status).to eq(200) }
      end
      context 'with invalid box filter' do
        before { get :tours, params: { sw:"48.615629449762814-1.8729114532470703", ne:"49.24715808228131-2.8177356719970703", format: :json } }
        it { expect(response.status).to eq(200) }
      end

      context "has map points" do
        before(:each) do
          [tour1, tour2, tour3].each do |t|
            FactoryBot.create(:tour_point, tour: t, latitude: -35.2784167, longitude: 149.1294692)
            FactoryBot.create(:tour_point, tour: t, latitude: -35.2847287248353, longitude: 149.128350617137)
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
    describe 'encounters' do
      let!(:time) { Time.new(2009, 3, 11, 8, 25, 00) }
      before do
        Timecop.freeze(time)
        user.coordinated_organizations << user4.organization
      end
      let!(:user1) { create :pro_user, organization: user.organization }
      let!(:user2) { create :pro_user, organization: user.organization }
      let!(:user3) { create :pro_user }
      let!(:user4) { create :pro_user }
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
        it { expect(response.status).to eq(200) }
        it { expect(assigns[:encounters].map(&:id)).to eq [encounter1, encounter2, encounter3, encounter4, encounter7].map(&:id)}
        it { expect(assigns[:encounter_count]).to eq 5 }
        it { expect(assigns[:tourer_count]).to eq 3 }
        it { expect(assigns[:tour_count]).to eq 3 }
      end
      context 'with type filter' do
        before { get :encounters, params: { tour_type: 'medical', format: :json } }
        it { expect(response.status).to eq(200) }
        it { expect(assigns[:encounters]).to eq [encounter3, encounter4]}
        it { expect(assigns[:encounter_count]).to eq 2 }
        it { expect(assigns[:tourer_count]).to eq 1 }
        it { expect(assigns[:tour_count]).to eq 1 }
      end
      context 'with date range' do
        before { get :encounters, params: { date_range:'10/03/2009-11/03/2009', format: :json } }
        it { expect(response.status).to eq(200) }
        it { expect(assigns[:encounters]).to eq [encounter3, encounter4]}
        it { expect(assigns[:encounter_count]).to eq 2 }
        it { expect(assigns[:tourer_count]).to eq 1 }
        it { expect(assigns[:tour_count]).to eq 1 }
      end
      context 'with org filter' do
        before { get :encounters, params: { org: user4.organization.id, format: :json } }
        it { expect(response.status).to eq(200) }
        it { expect(assigns[:encounters]).to eq [encounter7]}
        it { expect(assigns[:encounter_count]).to eq 1 }
        it { expect(assigns[:tourer_count]).to eq 1 }
        it { expect(assigns[:tour_count]).to eq 1 }
      end
      context 'with incorrect org filter' do
        before { get :encounters, params: { org: user3.organization.id, format: :json } }
        it { expect(response.status).to eq(200) }
        it { expect(assigns[:encounters]).to eq []}
        it { expect(assigns[:encounter_count]).to eq 0 }
        it { expect(assigns[:tourer_count]).to eq 0 }
        it { expect(assigns[:tour_count]).to eq 0 }
      end

      context "bad decrypt encounter message" do
        before { Encounter.any_instance.stub(:message).and_raise(OpenSSL::Cipher::CipherError) }
        before { get :encounters, format: :json }
        it { expect(response.status).to eq(200) }
      end
    end
    describe 'send_message' do
      let!(:user1) { create :pro_user, organization: user.organization, device_type: :android, device_id:'deviceid1' }
      let!(:user2) { create :pro_user, organization: user.organization, device_type: :android, device_id:nil }
      let!(:user3) { create :pro_user, organization: user.organization, device_type: :android, device_id:'deviceid2' }
      let!(:user4) { create :pro_user, organization: user.organization, device_type: nil, device_id:'deviceid3' }
      let!(:user5) { create :pro_user }

      context "send message without recipients" do
        before { post :send_message, params: { id: user.organization.to_param, object:'object', message: 'message' } }
        it { should redirect_to dashboard_organizations_path }
      end

      context "send message to all organization user" do
        before { post :send_message, params: { id: user.organization.to_param, object:'object', message: 'message', recipients: 'all' } }
        it { should redirect_to dashboard_organizations_path }
      end

      context "send message to specific users" do
        before(:each) do
          Timecop.freeze(Time.parse("10/10/2010").at_beginning_of_day)
          @user_in_tour = FactoryBot.create(:user, organization: user.organization)
          FactoryBot.create(:tour, status: :ongoing, user: @user_in_tour, created_at: Date.parse("10/10/2010"))
          user_in_tour2 = FactoryBot.create(:user, organization: user.organization)
          FactoryBot.create(:tour, status: :ongoing, user: user_in_tour2, created_at: Date.parse("10/10/2010"))
        end
        before { post :send_message, params: { id: user.organization.to_param, object:'object', message: 'message', recipients: ["user_id_#{@user_in_tour.id}"] } }
        it { should redirect_to dashboard_organizations_path }
      end
    end
  end
  context 'no authentication' do
    describe '#edit' do
      before { get :edit, params: { id: 0 }  }
      it { expect(response.status).to eq(302) }
    end
    describe '#update' do
      before { put :update, params: { id: 0 } }
      it { expect(response.status).to eq(302) }
    end
    describe '#dashboard' do
      before { get :dashboard }
      it { expect(response.status).to eq(302) }
    end
    describe '#tours' do
      before { get :tours, format: :json }
      it { expect(response.status).to eq(302) }
    end
    describe '#encounters' do
      before { get :encounters, format: :json }
      it { expect(response.status).to eq(302) }
    end
  end

  describe "map_center" do
    let!(:user) { manager_basic_login }
    before { get :map_center, format: :json }
    it { expect(JSON.parse(response.body)).to eq([48.866051, 2.3565218]) }
  end

  describe "new" do
    let!(:user) { admin_basic_login }
    before { get :new }
    it { expect(assigns(:organization)).to be_a_new(Organization) }
  end

  describe "create" do
    let!(:user) { admin_basic_login }

    context "valid params" do
      let(:post_organization) { post :create, params: { "organization" => {"name"=>"gvjbh", "description"=>"gvj", "phone"=>"gvj", "address"=>"gjv", "logo_url"=>"", "user"=>{"first_name"=>"jvgh", "last_name"=>"gjv", "phone"=>"0612345678", "email"=>"gvj@hgvj.com"}} } }
      it { expect { post_organization }.to change { Organization.count }.by(1) }
      it { expect { post_organization }.to change { User.count }.by(1) }
    end

    context "creates user" do
      before { post :create, params: { "organization" => {"name"=>"gvjbh", "description"=>"gvj", "phone"=>"gvj", "address"=>"gjv", "logo_url"=>"", "user"=>{"first_name"=>"jvgh", "last_name"=>"gjv", "phone"=>"0612345678", "email"=>"gvj@hgvj.com"}} } }
      it { expect(User.last.manager).to be true }
    end

    context "upgrades existing user" do
      let!(:existing_user) { create :public_user, first_name: "Joe", last_name: nil, phone: "0612345678", email: nil }
      let(:post_organization) { post :create, params: { "organization" => {"name"=>"gvjbh", "description"=>"gvj", "phone"=>"gvj", "address"=>"gjv", "logo_url"=>"", "user"=>{"first_name"=>"jvgh", "last_name"=>"gjv", "phone"=>"0612345678", "email"=>"gvj@hgvj.com"}} } }
      it { expect { post_organization }.not_to change { User.count } }
      it { expect { post_organization }.to change { existing_user.reload.manager }.to true }
      it { expect { post_organization }.not_to change { existing_user.reload.first_name } }
      it { expect { post_organization }.to change { existing_user.reload.last_name }.to "gjv" }
      it { expect { post_organization }.to change { existing_user.reload.email }.to "gvj@hgvj.com" }
    end

    context "invalid user" do
      let(:post_organization) { post :create, params: { "organization" => {"name"=>"gvjbh", "description"=>"gvj", "phone"=>"gvj", "address"=>"gjv", "logo_url"=>"", "user"=>{"first_name"=>"jvgh", "last_name"=>"gjv", "phone"=>"cfghgvj", "email"=>"gvj@hgvj.com"}} } }
      it { expect { post_organization }.to change { Organization.count }.by(0) }
      it { expect { post_organization }.to change { User.count }.by(0) }
    end

    context "invalid organization" do
      let(:post_organization) { post :create, params: { "organization" => {"description"=>"gvj", "phone"=>"gvj", "address"=>"gjv", "logo_url"=>"", "user"=>{"first_name"=>"jvgh", "last_name"=>"gjv", "phone"=>"0612345678", "email"=>"gvj@hgvj.com"}} } }
      it { expect { post_organization }.to change { Organization.count }.by(0) }
      it { expect { post_organization }.to change { User.count }.by(0) }
    end
  end
end
