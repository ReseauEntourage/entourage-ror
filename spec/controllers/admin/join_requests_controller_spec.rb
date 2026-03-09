require 'rails_helper'
include AuthHelper

describe Admin::JoinRequestsController do
  let!(:user) { admin_basic_login }
  let(:neighborhood) { create(:neighborhood) }
  let(:member) { create(:public_user) }
  let!(:join_request) { create(:join_request, joinable: neighborhood, user: member, status: :accepted, role: :member) }

  describe 'DELETE #destroy' do
    let(:do_request) { delete :destroy, params: { id: join_request.id } }

    context 'as a moderator' do
      before { user.update(roles: [:moderator]) }

      it { expect { do_request }.to change { join_request.reload.status }.from('accepted').to('cancelled') }
      it {
        do_request
        expect(response).to redirect_to(show_members_admin_neighborhood_path(neighborhood))
      }
    end

    context 'as a non-moderator' do
      before { user.update(roles: []) }

      it { expect { do_request }.not_to change { join_request.reload.status } }
      it {
        do_request
        expect(response.status).to eq(401)
      }
    end

    context 'for an outing' do
      let(:outing) { create(:outing) }
      let!(:join_request) { create(:join_request, joinable: outing, user: member, status: :accepted, role: :participant) }

      before { user.update(roles: [:moderator]) }

      it { expect { do_request }.to change { join_request.reload.status }.from('accepted').to('cancelled') }
      it {
        do_request
        expect(response).to redirect_to(show_members_admin_entourage_path(outing))
      }
    end
  end
end
