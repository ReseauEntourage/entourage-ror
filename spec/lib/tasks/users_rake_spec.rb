require 'rails_helper'
require 'rake'

describe 'users rake tasks' do
  before(:all) do
    Rake.application = Rake::Application.new
    Rake.application.rake_require('tasks/users', [Rails.root.join('lib').to_s])
    Rake::Task.define_task(:environment)
  end

  after(:all) { Rake.application = Rake::Application.new }

  def run_task(name)
    Rake::Task[name].reenable
    Rake::Task[name].invoke
  end

  describe 'users:engagement_levels' do
    # stubbed: REFRESH MATERIALIZED VIEW CONCURRENTLY can't run inside the
    # spec's wrapping transaction
    it 'refreshes the engagement_levels materialized view inline' do
      expect(RefreshEngagementLevelsJob).to receive(:perform_now)

      run_task('users:engagement_levels')
    end
  end

  describe 'users:restore_blocked_status' do
    let(:moderator) { create(:pro_user, phone: '+33600000001', token: 'mod') }
    let!(:user) do
      create(:public_user, phone: '+33611111111').tap do |u|
        UserServices::DeleteUserService.new(user: u).delete
        UserHistory.create!(user_id: u.id, updater_id: moderator.id, kind: 'block', metadata: {})
      end
    end

    after { ENV.delete('DRY_RUN') }

    it 'only reports by default' do
      expect { run_task('users:restore_blocked_status') }.to output(/DRY RUN: would set 1 deleted account/).to_stdout
      expect(user.reload.validation_status).to eq('deleted')
    end

    it 'writes with DRY_RUN=false' do
      ENV['DRY_RUN'] = 'false'

      expect { run_task('users:restore_blocked_status') }.to output(/Set 1 deleted account/).to_stdout
      expect(user.reload.validation_status).to eq('blocked')
    end
  end

  describe 'users:engagement_segments' do
    let!(:user) { create(:user, last_sign_in_at: 1.day.ago, targeting_profile: nil, deleted: false) }

    before { create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'reaction', date: Date.current) }

    it 'computes and stores engagement segments inline, without going through Sidekiq' do
      expect { run_task('users:engagement_segments') }
        .to change { UserSegment.where(user_id: user.id, engagement_segment: 'Curieux').count }.from(0).to(1)
    end
  end
end
