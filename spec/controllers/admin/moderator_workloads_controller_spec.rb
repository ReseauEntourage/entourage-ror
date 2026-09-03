require 'rails_helper'
include AuthHelper

describe Admin::ModeratorWorkloadsController do
  let!(:admin) { admin_basic_login }
  let!(:moderator1) { FactoryBot.create(:admin_user, roles: [:moderator], validation_status: 'validated', phone: '+33711111111') }
  let!(:moderator2) { FactoryBot.create(:admin_user, roles: [:moderator], validation_status: 'validated', phone: '+33722222222') }

  describe 'GET index' do
    let!(:assigned_open) { FactoryBot.create(:entourage, status: 'open', group_type: 'action') }
    let!(:assigned_unmoderated) { FactoryBot.create(:entourage, status: 'open', group_type: 'action') }
    let!(:unrelated) { FactoryBot.create(:entourage, status: 'open', group_type: 'action') }

    before do
      moderation = assigned_open.moderation || assigned_open.build_moderation
      moderation.update!(moderator: moderator1, moderated_at: Time.zone.now)

      moderation = assigned_unmoderated.moderation || assigned_unmoderated.build_moderation
      moderation.update!(moderator: moderator1, moderated_at: nil)

      moderation = unrelated.moderation || unrelated.build_moderation
      moderation.update!(moderator: moderator2)

      get :index
    end

    it { expect(response).to be_successful }

    it 'counts open entourages assigned to each moderator' do
      row = assigns(:rows).find { |r| r[:moderator] == moderator1 }
      expect(row[:open_count]).to eq(2)
      expect(row[:unmoderated_count]).to eq(1)
    end

    it 'sorts moderators by queue size, busiest first' do
      moderators_by_load = assigns(:rows).map { |r| r[:moderator] }
      expect(moderators_by_load.first).to eq(moderator1)
    end
  end
end
