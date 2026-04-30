require 'rails_helper'

RSpec.describe BadgesService do
  let(:user) { create(:public_user, targeting_profile: 'asks_for_help') }

  describe '.eligible_user?' do
    it { expect(BadgesService.eligible_user?(user)).to be true }
    it { expect(BadgesService.eligible_user?(create(:public_user, targeting_profile: 'offers_help'))).to be true }
    it { expect(BadgesService.eligible_user?(create(:public_user, targeting_profile: 'partner'))).to be false }
  end

  describe '.check_bienvenue' do
    context 'when onboarding is not complete' do
      it 'does not award badge' do
        expect {
          BadgesService.check_bienvenue(user)
        }.not_to change(UserBadge, :count)
      end
    end

    context 'when onboarding is complete but no engagement' do
      before do
        user.update(
          interest_list: ['sport'],
          involvement_list: ['outings'],
          concern_list: ['social'],
          availability: { "1" => ["09:00-12:00"] }
        )
      end

      it 'does not award badge' do
        expect {
          BadgesService.check_bienvenue(user)
        }.not_to change(UserBadge, :count)
      end
    end

    context 'when onboarding is complete and first engagement' do
      before do
        user.update(
          interest_list: ['sport'],
          involvement_list: ['outings'],
          concern_list: ['social'],
          availability: { "1" => ["09:00-12:00"] }
        )
        create(:chat_message, user: user)
      end

      it 'awards badge' do
        expect {
          BadgesService.check_bienvenue(user)
        }.to change(UserBadge, :count).by(1)

        badge = UserBadge.last
        expect(badge.badge_tag).to eq('bienvenue')
        expect(badge.active).to be true
      end
    end
  end

  describe '.check_premier_contact' do
    let(:other_user) { create(:public_user, targeting_profile: 'offers_help', created_at: 2.days.ago) }
    let(:conversation) { create(:entourage, group_type: :conversation) }
    let!(:jr1) { create(:join_request, user: user, joinable: conversation, status: 'accepted') }
    let!(:jr2) { create(:join_request, user: other_user, joinable: conversation, status: 'accepted') }

    before do
      user.update(created_at: 2.days.ago)
    end

    it 'awards badge when both participants have messaged' do
      create(:chat_message, user: other_user, messageable: conversation)
      msg = create(:chat_message, user: user, messageable: conversation)

      expect {
        BadgesService.check_premier_contact(msg)
      }.to change(UserBadge, :count).by(2)
    end

    it 'does not award badge if only one participant messaged' do
      msg = create(:chat_message, user: user, messageable: conversation)

      expect {
        BadgesService.check_premier_contact(msg)
      }.not_to change(UserBadge, :count)
    end
  end

  describe '.check_moteur_rencontres' do
    it 'awards badge when 3 outings created in 90 days' do
      3.times { create(:outing, user: user, metadata: { starts_at: 10.days.from_now }) }

      expect {
        BadgesService.check_moteur_rencontres(user)
      }.to change(UserBadge, :count).by(1)

      expect(UserBadge.last.active).to be true
    end

    it 'deactivates badge when count drops below 3' do
      create(:user_badge, user: user, badge_tag: 'moteur_rencontres', active: true)
      create(:outing, user: user, metadata: { starts_at: 100.days.ago }) # Old one

      BadgesService.check_moteur_rencontres(user)
      expect(UserBadge.last.active).to be false
    end
  end

  describe '.check_fidele_papotages' do
    it 'awards badge when 6 papotages attended in 90 days' do
      6.times do |i|
        outing = create(:outing, online: true, title: "Papotage #{i}", metadata: { starts_at: 10.days.from_now })
        create(:join_request, user: user, joinable: outing, status: 'accepted')
      end

      expect {
        BadgesService.check_fidele_papotages(user)
      }.to change(UserBadge, :count).by(1)
    end
  end

  describe '.check_voix_presente' do
    it 'awards badge when 3/4 weeks have actions' do
      3.times { |i| create(:weekly_activity, user: user, week_iso: "2024-W0#{i+1}", has_group_action: true) }
      create(:weekly_activity, user: user, week_iso: "2024-W04", has_group_action: false)

      expect {
        BadgesService.check_voix_presente(user)
      }.to change(UserBadge, :count).by(1)
    end

    it 'deactivates badge only after 2 consecutive weeks without action' do
      create(:user_badge, user: user, badge_tag: 'voix_presente', active: true)

      # 1 week without action -> still active
      create(:weekly_activity, user: user, week_iso: "2024-W05", has_group_action: false)
      BadgesService.check_voix_presente(user)
      expect(UserBadge.last.active).to be true

      # 2 weeks without action -> deactivated
      create(:weekly_activity, user: user, week_iso: "2024-W04", has_group_action: false)
      BadgesService.check_voix_presente(user)
      expect(UserBadge.last.active).to be false
    end
  end
end
