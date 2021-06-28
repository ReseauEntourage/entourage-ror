require 'rails_helper'
include AuthHelper

describe Admin::SuperAdminController do
  let!(:user) { super_admin_basic_login }
  let!(:main_moderator) { create :admin_user }

  describe 'GET #entourage_images' do
    let!(:entourage_image_list) { FactoryBot.create_list(:entourage_image, 2, landscape_url: 'entourage_images/images/landscape.png') }

    context "has entourage_images" do
      before { get :entourage_images }

      it { expect(assigns(:entourage_images).map(&:id)).to match_array(entourage_image_list.map(&:id)) }
    end
  end

  describe 'GET #outings_images' do
    let!(:outing_list) { FactoryBot.create_list(:outing, 2, metadata: {
        landscape_url: 'entourage_images/images/landscape.png'
    }) }

    context "has outings_images" do
      before { get :outings_images }

      it { expect(assigns(:outings).map(&:id)).to match_array(outing_list.map(&:id)) }
    end
  end

  describe 'GET #announcements_images' do
    let!(:announcement_list) { FactoryBot.create_list(:announcement, 2, image_url: 'https://entourage_images/images/landscape.png', user_goals: [:offer_help], areas: [:dep_75], id: [1, 2]) }

    context "has announcements_images" do
      before { get :announcements_images }

      it { expect(assigns(:announcements).map(&:id)).to match_array(announcement_list.map(&:id)) }
    end
  end
end
