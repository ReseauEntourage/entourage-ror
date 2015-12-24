require 'rails_helper'
include AuthHelper

RSpec.describe ToursController, :type => :controller do

  let(:tour) { FactoryGirl.create(:tour) }

  describe 'GET show' do
    context "not logged in" do
      before { get 'show', id: tour.to_param }
      it { should redirect_to new_session_path }
    end

    context "logged in as user" do
      let!(:user) { user_basic_login }

      context "access somebody else tour" do
        before { get 'show', id: tour.to_param }
        it { should redirect_to root_path }
      end

      context "access one of my tours" do
        let!(:user_tour) { FactoryGirl.create(:tour, user: user) }
        before { get 'show', id: user_tour.to_param }
        it { should render_template 'show' }
        it { expect(assigns(:tour)).to eq(user_tour) }
      end
    end
  end
end