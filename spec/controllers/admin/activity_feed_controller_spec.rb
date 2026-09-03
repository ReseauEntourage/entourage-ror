require 'rails_helper'
include AuthHelper

describe Admin::ActivityFeedController do
  let!(:admin) { admin_basic_login }

  describe 'GET index' do
    let!(:recent_user) { FactoryBot.create(:public_user, community: admin.community, created_at: 1.hour.ago) }
    let!(:old_user) { FactoryBot.create(:public_user, community: admin.community, created_at: 10.days.ago) }
    let!(:recent_entourage) { FactoryBot.create(:entourage, created_at: 2.hours.ago) }
    let!(:old_entourage) { FactoryBot.create(:entourage, created_at: 10.days.ago) }

    before { get :index }

    it { expect(response).to be_successful }

    it 'includes recent records only' do
      records = assigns(:items).map { |item| item[:record] }
      expect(records).to include(recent_user, recent_entourage)
      expect(records).not_to include(old_user, old_entourage)
    end

    it 'orders items by created_at descending' do
      timestamps = assigns(:items).map { |item| item[:created_at] }
      expect(timestamps).to eq(timestamps.sort.reverse)
    end
  end
end
