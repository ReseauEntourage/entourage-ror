require 'rails_helper'

RSpec.describe BadgeDeactivationWarningJob do
  def eligible_user
    create(:public_user, goal: 'ask_for_help')
  end

  def active_badge(user, tag)
    create(:user_badge, user: user, badge_tag: tag, active: true,
           metadata: { current: 3, target: 3 })
  end

  def stub_no_mail
    allow(BadgeMailer).to receive(:deactivation_warning).and_call_original
  end

  before { allow(EventBus).to receive(:publish) }

  subject(:perform) { BadgeDeactivationWarningJob.new.perform }

  describe 'moteur_rencontres' do
    let(:user) { eligible_user }
    before { active_badge(user, 'moteur_rencontres') }

    context 'when 2 outings are within the J+7 window (last 83 days)' do
      before do
        2.times { create(:outing, user: user, status: 'closed', created_at: 10.days.ago) }
      end

      it 'sends a deactivation warning email' do
        expect(BadgeMailer).to receive(:deactivation_warning).with(user, 'moteur_rencontres', 2, 3).and_return(double(deliver_later: nil))
        perform
      end
    end

    context 'when 3 outings are within the J+7 window' do
      before do
        3.times { create(:outing, user: user, status: 'closed', created_at: 10.days.ago) }
      end

      it 'does not send an email' do
        expect(BadgeMailer).not_to receive(:deactivation_warning).with(user, anything, anything, anything)
        perform
      end
    end

    context 'when 1 outing is within the J+7 window' do
      before do
        create(:outing, user: user, status: 'closed', created_at: 10.days.ago)
      end

      it 'sends a warning email with current=1' do
        expect(BadgeMailer).to receive(:deactivation_warning).with(user, 'moteur_rencontres', 1, 3).and_return(double(deliver_later: nil))
        perform
      end
    end

    context 'when badge is inactive' do
      before do
        UserBadge.find_by(user: user, badge_tag: 'moteur_rencontres').update!(active: false)
        create(:outing, user: user, status: 'closed', created_at: 10.days.ago)
      end

      it 'does not send an email' do
        expect(BadgeMailer).not_to receive(:deactivation_warning)
        perform
      end
    end

    context 'when user was already warned within the last 90 days' do
      before do
        create(:outing, user: user, status: 'closed', created_at: 10.days.ago)
        campaign = EmailCampaign.create!(name: 'badge_warning_moteur_rencontres')
        campaign.deliveries.create!(user: user, sent_at: 30.days.ago)
      end

      it 'does not send a new email' do
        expect(BadgeMailer).not_to receive(:deactivation_warning)
        perform
      end
    end

    context 'when the previous warning was sent more than 90 days ago' do
      before do
        create(:outing, user: user, status: 'closed', created_at: 10.days.ago)
        campaign = EmailCampaign.create!(name: 'badge_warning_moteur_rencontres')
        campaign.deliveries.create!(user: user, sent_at: 91.days.ago)
      end

      it 'sends a new warning email' do
        expect(BadgeMailer).to receive(:deactivation_warning).with(user, 'moteur_rencontres', 1, 3).and_return(double(deliver_later: nil))
        perform
      end
    end
  end

  describe 'fidele_papotages' do
    let(:user) { eligible_user }
    before { active_badge(user, 'fidele_papotages') }

    def create_papotage_participation(user, starts_at)
      outing = create(:outing, title: 'Papotage du quartier', online: true, status: 'closed',
                      metadata: { starts_at: starts_at.iso8601, ends_at: (starts_at + 1.hour).iso8601 })
      create(:join_request, user: user, joinable: outing, status: 'accepted',
             participate_at: starts_at)
    end

    context 'when 2 papotage participations are within the J+7 window' do
      before do
        2.times { create_papotage_participation(user, 10.days.ago) }
      end

      it 'sends a deactivation warning email' do
        expect(BadgeMailer).to receive(:deactivation_warning).with(user, 'fidele_papotages', 2, 3).and_return(double(deliver_later: nil))
        perform
      end
    end

    context 'when 3 papotage participations are within the J+7 window' do
      before do
        3.times { create_papotage_participation(user, 10.days.ago) }
      end

      it 'does not send an email' do
        expect(BadgeMailer).not_to receive(:deactivation_warning).with(user, anything, anything, anything)
        perform
      end
    end
  end

  describe 'voix_presente' do
    let(:user) { eligible_user }
    before { active_badge(user, 'voix_presente') }

    context 'when 2 weekly activities are within the J+7 window' do
      before do
        cutoff = BadgeDeactivationWarningJob::J7_WINDOW_DAYS.days.ago.to_date
        create(:weekly_activity, user: user, week_iso: (cutoff + 7.days).strftime('%G-W%V'))
        create(:weekly_activity, user: user, week_iso: Date.today.strftime('%G-W%V'))
      end

      it 'sends a deactivation warning email' do
        expect(BadgeMailer).to receive(:deactivation_warning).with(user, 'voix_presente', 2, 3).and_return(double(deliver_later: nil))
        perform
      end
    end
  end

  describe 'irreversible badges are never processed' do
    let(:user) { eligible_user }

    before do
      create(:user_badge, user: user, badge_tag: 'bienvenue', active: true)
      create(:user_badge, user: user, badge_tag: 'premier_contact', active: true)
    end

    it 'does not send any email' do
      expect(BadgeMailer).not_to receive(:deactivation_warning)
      perform
    end
  end

  describe 'ineligible user is skipped' do
    let(:user) { create(:public_user, goal: 'organization') }
    before { active_badge(user, 'moteur_rencontres') }

    it 'does not send an email' do
      expect(BadgeMailer).not_to receive(:deactivation_warning)
      perform
    end
  end
end
