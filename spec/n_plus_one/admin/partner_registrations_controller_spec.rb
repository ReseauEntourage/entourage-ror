require 'rails_helper'
include AuthHelper

describe Admin::PartnerRegistrationsController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries', pending: 'N+1 : partner_join_requests, partners et addresses chargés par utilisateur (aucun preload dans le contrôleur, vue partner_registrations/index)' do
      def populate(count)
        count.times do
          member = create :public_user, goal: :organization
          create :address, user: member, postal_code: '75011'
          PartnerJoinRequest.create!(
            user: member,
            partner: create(:partner, name: "Asso #{SecureRandom.hex(4)}"),
            postal_code: '75012',
            partner_role_title: 'Bénévole'
          )
        end
      end

      def perform_request
        get :index
      end

      def returned_items_count
        assigns(:users).to_a.size
      end
    end
  end
end
