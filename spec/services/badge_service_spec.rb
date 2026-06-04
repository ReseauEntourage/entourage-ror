require 'rails_helper'

RSpec.describe BadgeService do
  def eligible_user
    create(:public_user, goal: 'ask_for_help')
  end

  def complete_onboarding(user)
    user.update!(
      interest_list: ['activites'],
      involvement_list: ['resources'],
      concern_list: ['sharing_time'],
      availability: { "1" => ["09:00-10:00"] }
    )
  end

  # Prevent after_commit hooks from triggering the badge service during test setup
  before { allow(EventBus).to receive(:publish) }

  describe '.eligible_user?' do
    it 'returns true for ask_for_help public user' do
      user = create(:public_user, goal: 'ask_for_help')
      expect(BadgeService.eligible_user?(user)).to be true
    end

    it 'returns true for offer_help public user' do
      user = create(:public_user, goal: 'offer_help')
      expect(BadgeService.eligible_user?(user)).to be true
    end

    it 'returns false for nil' do
      expect(BadgeService.eligible_user?(nil)).to be false
    end

    it 'returns false for anonymous user' do
      user = create(:public_user, goal: 'ask_for_help')
      allow(user).to receive(:anonymous?).and_return(true)
      expect(BadgeService.eligible_user?(user)).to be false
    end

    it 'returns false for user with no goal' do
      user = create(:public_user, goal: nil)
      expect(BadgeService.eligible_user?(user)).to be false
    end
  end

  describe '.check_bienvenue' do
    let(:user) { eligible_user }

    before { complete_onboarding(user) }

    context 'when user already has the badge' do
      before { create(:user_badge, user: user, badge_tag: 'bienvenue') }

      it 'does not create a duplicate badge' do
        create(:user_reaction, user: user)
        expect { BadgeService.check_bienvenue(user) }
          .not_to change { UserBadge.where(user: user, badge_tag: 'bienvenue').count }
      end
    end

    context 'when onboarding is not complete' do
      before { user.update!(interest_list: []) }

      it 'does not award the badge' do
        expect { BadgeService.check_bienvenue(user) }
          .not_to change { UserBadge.count }
      end
    end

    context 'when first engagement is detected via user_reaction' do
      before { create(:user_reaction, user: user) }

      it 'awards the bienvenue badge' do
        expect { BadgeService.check_bienvenue(user) }
          .to change { UserBadge.where(user: user, badge_tag: 'bienvenue').count }.by(1)
      end
    end

    context 'when first engagement is detected via accepted outing join_request' do
      before do
        outing = create(:outing)
        create(:join_request, user: user, joinable: outing, status: 'accepted')
      end

      it 'awards the bienvenue badge' do
        expect { BadgeService.check_bienvenue(user) }
          .to change { UserBadge.where(user: user, badge_tag: 'bienvenue').count }.by(1)
      end
    end

    context 'when first engagement is detected via watched resource' do
      before do
        resource = create(:resource)
        create(:users_resource, user: user, resource: resource, watched: true)
      end

      it 'awards the bienvenue badge' do
        expect { BadgeService.check_bienvenue(user) }
          .to change { UserBadge.where(user: user, badge_tag: 'bienvenue').count }.by(1)
      end
    end

    context 'when first engagement is detected via chat message' do
      before { create(:chat_message, user: user) }

      it 'awards the bienvenue badge' do
        expect { BadgeService.check_bienvenue(user) }
          .to change { UserBadge.where(user: user, badge_tag: 'bienvenue').count }.by(1)
      end
    end

    context 'when user is not eligible' do
      let(:user) { create(:public_user, goal: nil) }

      before { complete_onboarding(user) }

      it 'does not award the badge' do
        create(:user_reaction, user: user)
        expect { BadgeService.check_bienvenue(user) }
          .not_to change { UserBadge.count }
      end
    end

    context 'when no engagement exists' do
      it 'does not award the badge' do
        expect { BadgeService.check_bienvenue(user) }
          .not_to change { UserBadge.count }
      end
    end
  end

  describe '.check_premier_contact' do
    let(:user1) { eligible_user }
    let(:user2) { eligible_user }
    let(:conversation) { create(:conversation, participants: [user1, user2]) }

    before do
      user1.update_column(:created_at, 2.days.ago)
      user2.update_column(:created_at, 2.days.ago)
    end

    context 'when other participant has already sent a message' do
      let!(:other_message) do
        create(:chat_message, messageable: conversation, user: user2, message_type: 'text')
      end

      it 'awards premier_contact to sender' do
        message = create(:chat_message, messageable: conversation, user: user1, message_type: 'text')
        BadgeService.check_premier_contact(message)
        expect(UserBadge.where(user: user1, badge_tag: 'premier_contact')).to exist
      end

      it 'awards premier_contact to other eligible participant' do
        message = create(:chat_message, messageable: conversation, user: user1, message_type: 'text')
        BadgeService.check_premier_contact(message)
        expect(UserBadge.where(user: user2, badge_tag: 'premier_contact')).to exist
      end
    end

    context 'when message is not in a conversation' do
      it 'does not award the badge' do
        message = create(:chat_message, user: user1)
        expect { BadgeService.check_premier_contact(message) }
          .not_to change { UserBadge.count }
      end
    end

    context 'when the other participant has not sent a message' do
      it 'does not award the badge' do
        message = create(:chat_message, messageable: conversation, user: user1, message_type: 'text')
        expect { BadgeService.check_premier_contact(message) }
          .not_to change { UserBadge.count }
      end
    end

    context 'when one participant was created less than 24h ago' do
      before { user1.update_column(:created_at, 1.hour.ago) }

      let!(:other_message) do
        create(:chat_message, messageable: conversation, user: user2, message_type: 'text')
      end

      it 'does not award the badge' do
        message = create(:chat_message, messageable: conversation, user: user1, message_type: 'text')
        BadgeService.check_premier_contact(message)
        expect(UserBadge.where(badge_tag: 'premier_contact')).not_to exist
      end
    end

    context 'when sender already has the badge' do
      let!(:other_message) do
        create(:chat_message, messageable: conversation, user: user2, message_type: 'text')
      end

      before { create(:user_badge, user: user1, badge_tag: 'premier_contact') }

      it 'does not create a duplicate badge for sender' do
        message = create(:chat_message, messageable: conversation, user: user1, message_type: 'text')
        expect { BadgeService.check_premier_contact(message) }
          .not_to change { UserBadge.where(user: user1, badge_tag: 'premier_contact').count }
      end
    end
  end

  describe '.check_moteur_rencontres' do
    let(:user) { eligible_user }

    context 'when user has organized 3+ outings in the last 90 days' do
      before do
        3.times { create(:outing, user: user, status: 'closed', created_at: 30.days.ago) }
      end

      it 'awards the badge' do
        BadgeService.check_moteur_rencontres(user)
        expect(UserBadge.where(user: user, badge_tag: 'moteur_rencontres', active: true)).to exist
      end

      it 'sets metadata with current count' do
        BadgeService.check_moteur_rencontres(user)
        badge = UserBadge.find_by(user: user, badge_tag: 'moteur_rencontres')
        expect(badge.metadata['current']).to eq(3)
        expect(badge.metadata['target']).to eq(3)
      end
    end

    context 'when user has fewer than 3 outings' do
      before do
        2.times { create(:outing, user: user, status: 'closed', created_at: 30.days.ago) }
      end

      it 'does not award the badge' do
        BadgeService.check_moteur_rencontres(user)
        badge = UserBadge.find_by(user: user, badge_tag: 'moteur_rencontres')
        expect(badge&.active).not_to be true
      end
    end

    context 'when outings are outside the 90-day window' do
      before do
        3.times { create(:outing, user: user, status: 'closed', created_at: 100.days.ago) }
      end

      it 'does not award the badge' do
        BadgeService.check_moteur_rencontres(user)
        badge = UserBadge.find_by(user: user, badge_tag: 'moteur_rencontres')
        expect(badge&.active).not_to be true
      end
    end

    context 'when user previously had the badge but no longer qualifies' do
      before do
        3.times { create(:outing, user: user, status: 'closed', created_at: 30.days.ago) }
        BadgeService.check_moteur_rencontres(user)
        Outing.where(user: user).update_all(created_at: 100.days.ago)
      end

      it 'deactivates the badge' do
        BadgeService.check_moteur_rencontres(user)
        badge = UserBadge.find_by(user: user, badge_tag: 'moteur_rencontres')
        expect(badge.active).to be false
      end
    end
  end

  describe '.check_fidele_papotages' do
    let(:user) { eligible_user }

    context 'when user has participated in 3+ papotages in the last 90 days' do
      before do
        3.times do
          outing = create(:outing, title: 'Papotage du quartier', online: true, status: 'closed',
                          metadata: { starts_at: 30.days.ago, ends_at: 29.days.ago })
          create(:join_request, user: user, joinable: outing, status: 'accepted',
                 participate_at: 30.days.ago)
        end
      end

      it 'awards the badge' do
        BadgeService.check_fidele_papotages(user)
        expect(UserBadge.where(user: user, badge_tag: 'fidele_papotages', active: true)).to exist
      end
    end

    context 'when user has participated in fewer than 3 papotages' do
      before do
        outing = create(:outing, title: 'Papotage du quartier', online: true, status: 'closed',
                        metadata: { starts_at: 30.days.ago, ends_at: 29.days.ago })
        create(:join_request, user: user, joinable: outing, status: 'accepted',
               participate_at: 30.days.ago)
      end

      it 'does not award the badge' do
        BadgeService.check_fidele_papotages(user)
        badge = UserBadge.find_by(user: user, badge_tag: 'fidele_papotages')
        expect(badge&.active).not_to be true
      end
    end

    context 'when participate_at is nil' do
      before do
        3.times do
          outing = create(:outing, title: 'Papotage du quartier', online: true, status: 'closed',
                          metadata: { starts_at: 30.days.ago, ends_at: 29.days.ago })
          create(:join_request, user: user, joinable: outing, status: 'accepted', participate_at: nil)
        end
      end

      it 'does not award the badge' do
        BadgeService.check_fidele_papotages(user)
        badge = UserBadge.find_by(user: user, badge_tag: 'fidele_papotages')
        expect(badge&.active).not_to be true
      end
    end
  end

  describe '.check_voix_presente' do
    let(:user) { eligible_user }

    context 'when user has 3+ weekly activities in last 4 weeks' do
      before do
        ['2026-W20', '2026-W21', '2026-W22'].each do |week|
          create(:weekly_activity, user: user, week_iso: week)
        end
      end

      it 'awards the badge' do
        BadgeService.check_voix_presente(user)
        expect(UserBadge.where(user: user, badge_tag: 'voix_presente', active: true)).to exist
      end
    end

    context 'when user has fewer than 3 weekly activities' do
      before do
        ['2026-W20', '2026-W21'].each do |week|
          create(:weekly_activity, user: user, week_iso: week)
        end
      end

      it 'does not award the badge' do
        BadgeService.check_voix_presente(user)
        badge = UserBadge.find_by(user: user, badge_tag: 'voix_presente')
        expect(badge&.active).not_to be true
      end
    end

    context 'when user has 5 activities but only the 4 most recent are counted' do
      before do
        ['2026-W17', '2026-W18', '2026-W19', '2026-W20', '2026-W21'].each do |week|
          create(:weekly_activity, user: user, week_iso: week)
        end
      end

      it 'awards the badge because top 4 contains 3+' do
        BadgeService.check_voix_presente(user)
        expect(UserBadge.where(user: user, badge_tag: 'voix_presente', active: true)).to exist
      end
    end
  end

  describe '.update_badge_status (private)' do
    let(:user) { eligible_user }

    context 'when should_be_active is true' do
      it 'creates and activates the badge with metadata' do
        BadgeService.send(:update_badge_status, user, 'moteur_rencontres', true, { current: 3, target: 3 })
        badge = UserBadge.find_by(user: user, badge_tag: 'moteur_rencontres')
        expect(badge).to be_present
        expect(badge.active).to be true
        expect(badge.metadata).to eq({ 'current' => 3, 'target' => 3 })
      end
    end

    context 'when should_be_active is false' do
      before do
        BadgeService.send(:update_badge_status, user, 'moteur_rencontres', true, { current: 3, target: 3 })
      end

      it 'deactivates an existing badge and updates metadata' do
        BadgeService.send(:update_badge_status, user, 'moteur_rencontres', false, { current: 1, target: 3 })
        badge = UserBadge.find_by(user: user, badge_tag: 'moteur_rencontres')
        expect(badge.active).to be false
        expect(badge.metadata).to eq({ 'current' => 1, 'target' => 3 })
      end

      it 'does nothing when no badge exists for inactive state' do
        expect {
          BadgeService.send(:update_badge_status, user, 'nonexistent', false, {})
        }.not_to raise_error
      end
    end
  end

  describe '.award_badge (private)' do
    let(:user) { eligible_user }

    it 'creates a new active badge' do
      BadgeService.send(:award_badge, user, 'bienvenue')
      badge = UserBadge.find_by(user: user, badge_tag: 'bienvenue')
      expect(badge).to be_present
      expect(badge.active).to be true
      expect(badge.awarded_at).to be_present
    end

    it 'does not update awarded_at if badge already exists and is active' do
      existing = create(:user_badge, user: user, badge_tag: 'bienvenue', active: true, awarded_at: 1.day.ago)
      BadgeService.send(:award_badge, user, 'bienvenue')
      expect(existing.reload.awarded_at).to be_within(1.second).of(1.day.ago)
    end

    it 'reactivates an inactive badge without resetting awarded_at' do
      original_time = 2.days.ago
      create(:user_badge, user: user, badge_tag: 'bienvenue', active: false, awarded_at: original_time)
      BadgeService.send(:award_badge, user, 'bienvenue')
      badge = UserBadge.find_by(user: user, badge_tag: 'bienvenue')
      expect(badge.active).to be true
      expect(badge.awarded_at).to be_within(1.second).of(original_time)
    end
  end

  describe '.deactivate_badge (private)' do
    let(:user) { eligible_user }

    it 'sets active to false' do
      create(:user_badge, user: user, badge_tag: 'bienvenue', active: true)
      BadgeService.send(:deactivate_badge, user, 'bienvenue')
      expect(UserBadge.find_by(user: user, badge_tag: 'bienvenue').active).to be false
    end

    it 'does nothing when badge does not exist' do
      expect {
        BadgeService.send(:deactivate_badge, user, 'bienvenue')
      }.not_to raise_error
    end
  end
end
