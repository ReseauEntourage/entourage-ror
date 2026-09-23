require 'rails_helper'
include AuthHelper

describe Admin::RecommandationsController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        @position ||= 0

        count.times do
          @position += 1
          create :recommandation, :offer_help, fragment: 0, name: "Reco #{@position}", position_offer_help: @position, image_url: "recommandations/image-#{@position}.jpg"
        end
      end

      def perform_request
        get :index, params: { profile: :offer_help, fragment: 0 }
      end

      def returned_items_count
        assigns(:recommandations).to_a.size
      end
    end
  end
end
