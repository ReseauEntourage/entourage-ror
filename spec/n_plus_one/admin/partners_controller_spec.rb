require 'rails_helper'
include AuthHelper

describe Admin::PartnersController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          # équipe interne (@staff_teams)
          create :partner, staff: true, name: "Staff #{SecureRandom.hex(4)}"

          # association (@partners) avec un admin et un membre
          partner = create :partner, staff: false, name: "Asso #{SecureRandom.hex(4)}"
          create :public_user, partner: partner, partner_admin: true
          create :public_user, partner: partner, partner_admin: false
        end
      end

      def perform_request
        get :index
      end

      def returned_items_count
        assigns(:partners).to_a.size + assigns(:staff_teams).to_a.size
      end
    end
  end
end
