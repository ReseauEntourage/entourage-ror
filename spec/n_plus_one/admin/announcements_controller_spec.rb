require 'rails_helper'
include AuthHelper

describe Admin::AnnouncementsController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          create :announcement,
            id: Announcement.maximum(:id).to_i + 1,
            status: :active,
            areas: [:dep_75, :hors_zone],
            user_goals: [:offer_help, :ask_for_help],
            image_url: "announcements/#{SecureRandom.hex(4)}.jpg",
            image_portrait_url: "announcements/portrait/#{SecureRandom.hex(4)}.jpg",
            category: :online
        end
      end

      def perform_request
        get :index
      end

      def returned_items_count
        assigns(:announcements).to_a.size
      end
    end
  end
end
