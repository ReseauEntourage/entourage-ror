require 'rails_helper'
include AuthHelper

describe Admin::DashboardController do
  render_views

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
    it { expect(assigns(:zone)).to eq(:all) }

    it 'includes a 1/7/30-day activity breakdown' do
      windows = assigns(:activity).map { |row| row[:days] }
      expect(windows).to eq([1, 7, 30])
    end

    it 'counts new users within each window' do
      row_30 = assigns(:activity).find { |r| r[:days] == 30 }
      row_1 = assigns(:activity).find { |r| r[:days] == 1 }

      expect(row_30[:new_users]).to be >= 2 # recent_user + old_user is out of range for day 1 only
      expect(row_1[:new_users]).to be >= 1 # recent_user
    end

    it { expect(assigns(:unassigned_count)).to be >= 1 }
    it { expect(assigns(:recent_blocks).map(&:user)).to include(blocked_user) }
    it { expect(assigns(:busiest_moderators)).to be_an(Array) }
    it { expect(assigns(:upcoming_outings_count)).to be_a(Integer) }
    it { expect(assigns(:unanswered_count)).to be_a(Integer) }
    it { expect(assigns(:avg_moderation_days)).to be_nil.or be_a(Numeric) }

    it 'counts new profile photos and new neighborhoods within each window' do
      row_30 = assigns(:activity).find { |r| r[:days] == 30 }
      expect(row_30).to have_key(:new_profile_photos)
      expect(row_30).to have_key(:new_neighborhoods)
    end
  end

  describe 'GET index average moderation delay' do
    let!(:moderated_entourage) { FactoryBot.create(:entourage, created_at: 3.days.ago) }

    before do
      moderation = moderated_entourage.moderation || moderated_entourage.build_moderation
      moderation.update!(moderated_at: moderated_entourage.created_at.to_date + 2.days)

      get :index
    end

    it 'computes the average delay in days' do
      expect(assigns(:avg_moderation_days)).to eq(2.0)
    end
  end

  describe 'GET index with a moderation zone' do
    let!(:moderator) { admin }
    let!(:area) { FactoryBot.create(:moderation_area, departement: '75', animator: moderator) }
    let!(:address) { FactoryBot.create(:address, postal_code: '75001', country: 'FR', user: FactoryBot.create(:public_user, community: admin.community)) }
    let!(:paris_user) { address.user }
    let!(:other_user) { FactoryBot.create(:public_user, community: admin.community) }

    before { get :index }

    it 'defaults to the moderator own zone when one exists' do
      expect(assigns(:zone)).to eq(:mine)
      expect(assigns(:departments)).to eq(['75'])
    end

    it 'scopes new users to the zone by default' do
      row_30 = assigns(:activity).find { |r| r[:days] == 30 }
      expect(row_30[:new_users]).to eq(1)
    end

    it 'switches to platform-wide figures on request' do
      get :index, params: { zone: 'all' }

      expect(assigns(:zone)).to eq(:all)
      row_30 = assigns(:activity).find { |r| r[:days] == 30 }
      expect(row_30[:new_users]).to be >= 2
    end
  end
end
