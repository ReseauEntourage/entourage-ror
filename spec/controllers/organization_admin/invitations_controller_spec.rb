require 'rails_helper'
include AuthHelper

describe OrganizationAdmin::InvitationsController do
  let!(:user) { organization_admin_basic_login }
  let!(:invitee) { FactoryBot.create(:partner_user, partner: user.partner) }

  describe 'GET #index' do
    let!(:partner_invitation) { FactoryBot.create(:partner_invitation, partner: user.partner, invitee: invitee) }

    context "has partner_invitations" do
      before { get :index, params: { status: :accepted } }

      it { expect(response.status).to eq(200)}
      it { expect(assigns(:invitations)).to match_array([partner_invitation]) }
    end
  end
end
