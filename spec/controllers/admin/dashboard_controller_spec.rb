require 'rails_helper'
include AuthHelper

describe Admin::DashboardController do
  let!(:admin) { admin_basic_login }

  describe 'GET index' do
    let!(:recent_user) { FactoryBot.create(:public_user, community: admin.community, created_at: 1.hour.ago) }
    let!(:old_user) { FactoryBot.create(:public_user, community: admin.community, created_at: 10.days.ago) }
    let!(:open_entourage) { FactoryBot.create(:entourage, status: 'open', group_type: 'action') }
    let!(:blocked_user) { FactoryBot.create(:public_user, community: admin.community) }

    before do
      UserHistory.create!(user: blocked_user, kind: 'block', updater: admin, created_at: 1.hour.ago)
      get :index
    end

    it { expect(response).to be_successful }
    it { expect(assigns(:new_users_count)).to be >= 1 }
    it { expect(assigns(:unassigned_count)).to be >= 1 }
    it { expect(assigns(:recent_blocks).map(&:user)).to include(blocked_user) }
    it { expect(assigns(:busiest_moderators)).to be_an(Array) }
  end
end
