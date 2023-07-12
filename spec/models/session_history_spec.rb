require 'rails_helper'

RSpec.describe SessionHistory, type: :model do
  let(:user) { create :public_user }
  let(:default_params) { {user_id: user.id, platform: 'test'} }

  before { SessionHistory.stub(:enable_tracking?) { true } }

  def track
    SessionHistory.track(**default_params)
  end

  def track_with_permission permission
    SessionHistory.track_notifications_permissions(**default_params.merge(notifications_permissions: permission))
  end

  describe ".track_notifications_permissions" do
    let(:permission) { 'permission_x' }
    let(:session_histories) { SessionHistory.where(default_params) }

    it "creates a session_history if none exists" do
      track_with_permission permission
      expect(session_histories.count).to eq 1
      expect(session_histories.first.notifications_permissions).to eq permission
    end

    it "updates the session_history if one exists" do
      track
      track_with_permission permission
      expect(session_histories.count).to eq 1
      expect(session_histories.first.notifications_permissions).to eq permission
    end
  end
end
