require 'rails_helper'
include AuthHelper

describe Admin::EntourageInvitationsController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          create :entourage_invitation, inviter: create(:pro_user), invitee: create(:pro_user), invitable: create(:entourage)
        end
      end

      def perform_request
        get :index
      end

      def returned_items_count
        assigns(:entourage_invitations).to_a.size
      end
    end
  end
end
