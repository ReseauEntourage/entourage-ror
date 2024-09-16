require 'rails_helper'
include AuthHelper

describe Admin::AnnouncementsController do

  let!(:user) { admin_basic_login }
  let!(:admin_user) { create :admin_user }

  describe 'GET #index' do
    let!(:announcement_list) { FactoryBot.create_list(:announcement, 2, user_goals: [:offer_help, :ask_for_help], areas: [:dep_75, :hors_zone], id: [1, 2]) }

    context "has announcements" do
      before { get :index }

      it { expect(assigns(:announcements)).to match_array(announcement_list) }
    end

    context "has announcements with default filtering" do
      before { get :index }

      it { expect(assigns(:announcements)).to match_array(announcement_list) }
    end

    context "has announcements with good filtering" do
      before { get :index, params: { user_goal: "offer_help", area: "dep_75" } }

      it { expect(assigns(:announcements)).to match_array(announcement_list) }
    end

    context "has no announcements when user_goal does not match" do
      before { get :index, params: { user_goal: "organization", area: "dep_75" } }

      it { expect(assigns(:announcements)).to eq([]) }
    end

    context "has no announcements when area does not match" do
      before { get :index, params: { user_goal: "offer_help", area: "sans_zone" } }

      it { expect(assigns(:announcements)).to eq([]) }
    end

    context "has announcements when area does not match but announcements are hors_zone" do
      before { get :index, params: { user_goal: "offer_help", area: "dep_92" } }

      it { expect(assigns(:announcements)).to match_array(announcement_list) }
    end
  end

  describe 'GET #index with empty table' do
    context "has no announcement" do
      before { get :index }
      it { expect(assigns(:announcements)).to eq([]) }
    end
  end
end
