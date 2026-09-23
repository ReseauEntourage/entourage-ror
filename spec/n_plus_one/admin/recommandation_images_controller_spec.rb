require 'rails_helper'
include AuthHelper

describe Admin::RecommandationImagesController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          n = RecommandationImage.count
          RecommandationImage.create!(title: "Photo #{n}", image_url: "recommandation/image_#{n}.jpg")
        end
      end

      def perform_request
        get :index
      end

      def returned_items_count
        assigns(:recommandation_images).to_a.size
      end
    end
  end
end
