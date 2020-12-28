require 'rails_helper'
include AuthHelper

RSpec.describe ToursController, :type => :controller do
  render_views

  let(:tour) { FactoryBot.create(:tour) }

  describe 'GET show' do
    context "not logged in" do
      before { get 'show', id: tour.to_param }
      it { should redirect_to new_session_path(continue: request.fullpath) }
    end

    context "logged in as user" do
      let!(:user) { user_basic_login }
      let(:tour) { FactoryBot.create(:tour) }

      context "access somebody else tour" do
        before { get 'show', id: tour.to_param }
        it { should redirect_to root_path }
      end

      context "access one of my tours" do
        let!(:user_tour) { FactoryBot.create(:tour, user: user) }
        before { get 'show', id: user_tour.to_param }
        it { should render_template 'show' }
        it { expect(assigns(:tour)).to eq(user_tour) }
      end

      context "tour without points" do
        let!(:user_tour) { FactoryBot.create(:tour, user: user, tour_points: []) }
        before { get 'show', id: user_tour.to_param }
        it { should render_template 'show' }
      end
    end

    context "logged in as manager" do
      let!(:user) { manager_basic_login }
      let!(:organisation_tour) { FactoryBot.create(:tour, user: FactoryBot.create(:pro_user, organization: user.organization)) }
      let!(:another_organisation_tour) { FactoryBot.create(:tour, user: FactoryBot.create(:pro_user)) }

      context "access somebody else tour outside my organisation" do
        before { get 'show', id: another_organisation_tour.to_param }
        it { should redirect_to root_path }
      end

      context "access somebody else tour from my organisation" do
        before { get 'show', id: organisation_tour.to_param }
        it { expect(response.status).to eq(200) }
      end
    end

    context "logged in as admin" do
      let!(:user) { admin_basic_login }
      let!(:organisation_tour) { FactoryBot.create(:tour, user: FactoryBot.create(:pro_user, organization: user.organization)) }
      let!(:another_organisation_tour) { FactoryBot.create(:tour, user: FactoryBot.create(:pro_user)) }

      context "access somebody else tour outside my organisation" do
        before { get 'show', id: another_organisation_tour.to_param }
        it { expect(response.status).to eq(200) }
      end

      context "access somebody else tour from my organisation" do
        before { get 'show', id: organisation_tour.to_param }
        it { expect(response.status).to eq(200) }
      end
    end
  end

  describe 'GET map_center' do
    context "has tour points" do
      context "not logged in" do
        before { get :map_center, id: tour.to_param }
        it { should redirect_to new_session_path(continue: request.fullpath) }
      end

      context "logged in as user" do
        let(:user) { user_basic_login }
        let(:user_tour) { FactoryBot.create(:tour, user: user) }

        context "has points" do
          let!(:tour_points) { FactoryBot.create_list(:tour_point, 2, tour: user_tour) }
          before { get :map_center, id: user_tour.to_param }
          it { expect(JSON.parse(response.body)).to eq({"tours"=>[1.5, 1.5]}) }
        end


        context "no points" do
          before { get :map_center, id: user_tour.to_param }
          it { expect(JSON.parse(response.body)).to eq({"tours"=>[]}) }
        end
      end
    end
  end


  describe 'GET map_data' do
    context "has tour points" do
      context "not logged in" do
        before { get :map_data, id: tour.to_param, format: :json }
        it { should redirect_to new_session_path(continue: request.fullpath) }
      end

      context "logged in as user" do
        let(:user) { user_basic_login }
        let(:user_tour) { FactoryBot.create(:tour, user: user) }
        let!(:tour_points) { FactoryBot.create_list(:simplified_tour_point, 2, tour: user_tour) }
        before { get :map_data, id: user_tour.to_param, format: :json }
        it { expect(JSON.parse(response.body)).to eq({"type"=>"FeatureCollection", "features"=>[{"type"=>"Feature", "properties"=>{"tour_type"=>"medical"}, "geometry"=>{"type"=>"LineString", "coordinates"=>[[1.5, 1.5], [1.5, 1.5]]}}]}) }
      end
    end
  end

  describe 'DELETE destroy' do
    let(:tour_creator) { create(:pro_user, admin: true, organization: organization) }
    let!(:tour) { create(:tour, user: tour_creator) }

    before { basic_login(tour_creator) }

    subject { delete 'destroy', id: tour.to_param }

    context "for a tour by standard organization" do
      let(:organization) { create(:organization) }
      it { should redirect_to root_path }
      it { expect { subject }.not_to change { Tour.count } }
    end

    context "for a tour by the Entourage organization" do
      let(:organization) { create(:organization, name: 'Entourage') }
      it { expect { subject }.to change { Tour.count }.by(-1) }
    end
  end
end
