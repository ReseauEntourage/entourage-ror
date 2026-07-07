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

    # 1.7 - Irréversibilité
    context 'when badge was already awarded and user has been inactive for 6+ months' do
      before { create(:user_badge, user: user, badge_tag: 'bienvenue', active: true, awarded_at: 180.days.ago) }

      it 'badge_active remains true (badge is irreversible)' do
        BadgeService.check_bienvenue(user)
        expect(UserBadge.find_by(user: user, badge_tag: 'bienvenue').active).to be true
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

      it 'still awards premier_contact to the other eligible participant' do
        message = create(:chat_message, messageable: conversation, user: user1, message_type: 'text')
        BadgeService.check_premier_contact(message)
        expect(UserBadge.where(user: user2, badge_tag: 'premier_contact')).to exist
      end
    end

    # 2.6 - Compte A (expéditeur) trop récent
    context 'when the sender (user A) was created less than 24h ago' do
      before do
        user1.update_column(:created_at, 1.hour.ago)
        create(:chat_message, messageable: conversation, user: user2, message_type: 'text')
      end

      it 'does not award the badge to either participant' do
        message = create(:chat_message, messageable: conversation, user: user1, message_type: 'text')
        BadgeService.check_premier_contact(message)
        expect(UserBadge.where(badge_tag: 'premier_contact')).not_to exist
      end
    end

    # 2.7 - Message bot/système exclu du comptage
    context 'when other participant only sent an auto/bot message' do
      before { create(:chat_message, messageable: conversation, user: user2, message_type: 'auto') }

      it 'does not count non-text/share messages as qualifying responses' do
        message = create(:chat_message, messageable: conversation, user: user1, message_type: 'text')
        BadgeService.check_premier_contact(message)
        expect(UserBadge.where(badge_tag: 'premier_contact')).not_to exist
      end
    end

    # 2.8 - Message animateur Entourage éligible
    context 'when sender is a pro/entourage team user' do
      let(:animateur) { create(:public_user, goal: 'ask_for_help') }
      let(:conv_with_animateur) { create(:conversation, participants: [animateur, user1]) }

      before do
        animateur.update_column(:created_at, 2.days.ago)
        create(:chat_message, messageable: conv_with_animateur, user: user1, message_type: 'text')
      end

      it 'awards the badge to the entourage team sender' do
        message = create(:chat_message, messageable: conv_with_animateur, user: animateur, message_type: 'text')
        BadgeService.check_premier_contact(message)
        expect(UserBadge.where(user: animateur, badge_tag: 'premier_contact')).to exist
      end

      it 'awards the badge to the eligible participant' do
        message = create(:chat_message, messageable: conv_with_animateur, user: animateur, message_type: 'text')
        BadgeService.check_premier_contact(message)
        expect(UserBadge.where(user: user1, badge_tag: 'premier_contact')).to exist
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

    # 3.2 - 3 événements dont 1 annulé → seulement 2 valides
    context 'when 3 outings were created but 1 is cancelled' do
      before do
        2.times { create(:outing, user: user, status: 'closed', created_at: 30.days.ago) }
        create(:outing, user: user, status: 'cancelled', created_at: 30.days.ago)
      end

      it 'does not count the cancelled outing and does not award the badge' do
        BadgeService.check_moteur_rencontres(user)
        badge = UserBadge.find_by(user: user, badge_tag: 'moteur_rencontres')
        expect(badge&.active).not_to be true
      end

      it 'sets metadata current count to 2' do
        BadgeService.check_moteur_rencontres(user)
        badge = UserBadge.find_by(user: user, badge_tag: 'moteur_rencontres')
        expect(badge.metadata['current']).to eq(2)
      end
    end

    # 3.3 - 3 événements co-animés
    context 'when user co-hosted 3 outings (organizer role in join_requests)' do
      it 'awards the badge (feature not yet implemented)' do
        pending 'Co-animated events (organizer role in join_requests but user_id != user) are not counted by check_moteur_rencontres'

        organizer = eligible_user
        3.times do
          outing = create(:outing, user: organizer, status: 'closed', created_at: 30.days.ago)
          create(:join_request, user: user, joinable: outing, status: 'accepted', role: 'organizer')
        end
        BadgeService.check_moteur_rencontres(user)
        expect(UserBadge.where(user: user, badge_tag: 'moteur_rencontres', active: true)).to exist
      end
    end

    # 3.4 - Mix 1 créé + 2 co-animés
    context 'when user created 1 outing and co-hosted 2 others (total = 3)' do
      it 'awards the badge (feature not yet implemented)' do
        pending 'Co-animated events (organizer role in join_requests but user_id != user) are not counted by check_moteur_rencontres'

        create(:outing, user: user, status: 'closed', created_at: 30.days.ago)
        organizer = eligible_user
        2.times do
          outing = create(:outing, user: organizer, status: 'closed', created_at: 30.days.ago)
          create(:join_request, user: user, joinable: outing, status: 'accepted', role: 'organizer')
        end
        BadgeService.check_moteur_rencontres(user)
        expect(UserBadge.where(user: user, badge_tag: 'moteur_rencontres', active: true)).to exist
      end
    end

    # 3.6 - Événement à la limite J-90 (inclusif)
    context 'when one outing was created exactly 90 days ago (boundary is inclusive)' do
      it 'counts the boundary event and awards the badge' do
        # Freeze time so 90.days.ago is identical at outing creation and at service check
        Timecop.freeze do
          2.times { create(:outing, user: user, status: 'closed', created_at: 30.days.ago) }
          create(:outing, user: user, status: 'closed', created_at: 90.days.ago)
          BadgeService.check_moteur_rencontres(user)
        end
        expect(UserBadge.where(user: user, badge_tag: 'moteur_rencontres', active: true)).to exist
      end
    end

    # 3.9 - Badge perdu puis reconquis
    context 'when badge was lost and then reconquered with new outings' do
      before do
        3.times { create(:outing, user: user, status: 'closed', created_at: 30.days.ago) }
        BadgeService.check_moteur_rencontres(user)
        Outing.where(user: user).update_all(created_at: 100.days.ago)
        BadgeService.check_moteur_rencontres(user)
        3.times { create(:outing, user: user, status: 'closed', created_at: 10.days.ago) }
      end

      it 'reactivates the badge' do
        BadgeService.check_moteur_rencontres(user)
        expect(UserBadge.find_by(user: user, badge_tag: 'moteur_rencontres').active).to be true
      end

      it 'preserves the original awarded_at date' do
        initial_awarded_at = UserBadge.find_by(user: user, badge_tag: 'moteur_rencontres').awarded_at
        BadgeService.check_moteur_rencontres(user)
        expect(UserBadge.find_by(user: user, badge_tag: 'moteur_rencontres').awarded_at)
          .to be_within(1.second).of(initial_awarded_at)
      end
    end

    # 3.11 - Annulation post-attribution → désactivation
    context 'when an outing is cancelled after the badge was awarded' do
      let!(:outings) { 3.times.map { create(:outing, user: user, status: 'closed', created_at: 30.days.ago) } }

      before do
        BadgeService.check_moteur_rencontres(user)
        outings.first.update_column(:status, 'cancelled')
      end

      it 'deactivates the badge after recalculation' do
        BadgeService.check_moteur_rencontres(user)
        expect(UserBadge.find_by(user: user, badge_tag: 'moteur_rencontres').active).to be false
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

    # 4.2 - Participation Bonne onde non comptabilisée
    context '4.2 - when user participated in bonne_onde events (not papotages)' do
      before do
        3.times do
          outing = create(:outing, title: 'Bonne onde du quartier', online: true, status: 'closed',
                          metadata: { starts_at: 30.days.ago, ends_at: 29.days.ago })
          create(:join_request, user: user, joinable: outing, status: 'accepted', participate_at: 30.days.ago)
        end
      end

      it 'does not award the badge (bonne_onde is not a papotage)' do
        BadgeService.check_fidele_papotages(user)
        badge = UserBadge.find_by(user: user, badge_tag: 'fidele_papotages')
        expect(badge&.active).not_to be true
      end
    end

    # 4.3 - Autre type d'événement non comptabilisé
    context '4.3 - when user participated in other offline events' do
      before do
        3.times do
          outing = create(:outing, title: 'Café du quartier', online: false, status: 'closed',
                          metadata: { starts_at: 30.days.ago, ends_at: 29.days.ago })
          create(:join_request, user: user, joinable: outing, status: 'accepted', participate_at: 30.days.ago)
        end
      end

      it 'does not award the badge (non-papotage events are not counted)' do
        BadgeService.check_fidele_papotages(user)
        badge = UserBadge.find_by(user: user, badge_tag: 'fidele_papotages')
        expect(badge&.active).not_to be true
      end
    end

    # 4.5 - Papotage hors fenêtre des 90 jours
    context '4.5 - when one papotage is outside the 90-day window' do
      before do
        2.times do
          outing = create(:outing, title: 'Papotage du quartier', online: true, status: 'closed',
                          metadata: { starts_at: 30.days.ago, ends_at: 29.days.ago })
          create(:join_request, user: user, joinable: outing, status: 'accepted', participate_at: 30.days.ago)
        end
        old_outing = create(:outing, title: 'Papotage du quartier', online: true, status: 'closed',
                            metadata: { starts_at: 91.days.ago, ends_at: 90.days.ago })
        create(:join_request, user: user, joinable: old_outing, status: 'accepted', participate_at: 91.days.ago)
      end

      it 'does not count the papotage outside the window' do
        BadgeService.check_fidele_papotages(user)
        badge = UserBadge.find_by(user: user, badge_tag: 'fidele_papotages')
        expect(badge&.active).not_to be true
      end

      it 'reflects count of 2 in metadata' do
        BadgeService.check_fidele_papotages(user)
        badge = UserBadge.find_by(user: user, badge_tag: 'fidele_papotages')
        expect(badge.metadata['current']).to eq(2)
      end
    end

    # 4.6 - Jauges : progression partielle exposée au front
    context '4.6 - when user has participated in 1 papotage (partial progress)' do
      before do
        outing = create(:outing, title: 'Papotage du quartier', online: true, status: 'closed',
                        metadata: { starts_at: 30.days.ago, ends_at: 29.days.ago })
        create(:join_request, user: user, joinable: outing, status: 'accepted', participate_at: 30.days.ago)
      end

      it 'exposes current=1 and target=3 in metadata' do
        BadgeService.check_fidele_papotages(user)
        badge = UserBadge.find_by(user: user, badge_tag: 'fidele_papotages')
        expect(badge.metadata).to eq({ 'current' => 1, 'target' => 3 })
      end
    end

    # 4.7 - Réversibilité : fenêtre tombe à 2
    context '4.7 - when one papotage falls outside the window (badge deactivated)' do
      let!(:outings) do
        3.times.map do
          create(:outing, title: 'Papotage du quartier', online: true, status: 'closed',
                 metadata: { starts_at: 30.days.ago, ends_at: 29.days.ago })
        end
      end

      before do
        outings.each do |outing|
          create(:join_request, user: user, joinable: outing, status: 'accepted', participate_at: 30.days.ago)
        end
        BadgeService.check_fidele_papotages(user)
        outings.first.update_column(:metadata, { 'starts_at' => 91.days.ago.to_s, 'ends_at' => 90.days.ago.to_s })
      end

      it 'deactivates the badge after recalculation' do
        BadgeService.check_fidele_papotages(user)
        expect(UserBadge.find_by(user: user, badge_tag: 'fidele_papotages').active).to be false
      end
    end

    # 4.8 - Inactif 3 mois : badge désactivé
    context '4.8 - when user has 0 participations with participate_at' do
      before do
        3.times do
          outing = create(:outing, title: 'Papotage du quartier', online: true, status: 'closed',
                          metadata: { starts_at: 30.days.ago, ends_at: 29.days.ago })
          create(:join_request, user: user, joinable: outing, status: 'accepted', participate_at: 30.days.ago)
        end
        BadgeService.check_fidele_papotages(user)
        JoinRequest.where(user: user).update_all(participate_at: nil)
      end

      it 'sets badge to inactive' do
        BadgeService.check_fidele_papotages(user)
        expect(UserBadge.find_by(user: user, badge_tag: 'fidele_papotages').active).to be false
      end
    end

    # 4.9 - Idempotence : badge déjà inactif, pas de badge.deactivated réémis
    context '4.9 - when badge is already inactive and count is still below threshold' do
      before do
        create(:user_badge, user: user, badge_tag: 'fidele_papotages', active: false, awarded_at: nil)
        outing = create(:outing, title: 'Papotage du quartier', online: true, status: 'closed',
                        metadata: { starts_at: 30.days.ago, ends_at: 29.days.ago })
        create(:join_request, user: user, joinable: outing, status: 'accepted', participate_at: 30.days.ago)
      end

      it 'does not create a duplicate badge record' do
        expect { BadgeService.check_fidele_papotages(user) }
          .not_to change { UserBadge.where(user: user, badge_tag: 'fidele_papotages').count }
      end

      it 'badge remains inactive' do
        BadgeService.check_fidele_papotages(user)
        expect(UserBadge.find_by(user: user, badge_tag: 'fidele_papotages').active).to be false
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

    # 5.9 - Réversibilité : semaine inactive fait tomber à 2/4
    context '5.9 - when user only has 2 weekly activities (badge deactivated)' do
      before do
        ['2026-W20', '2026-W21'].each { |w| create(:weekly_activity, user: user, week_iso: w) }
      end

      it 'does not award the badge' do
        BadgeService.check_voix_presente(user)
        badge = UserBadge.find_by(user: user, badge_tag: 'voix_presente')
        expect(badge&.active).not_to be true
      end

      context 'when badge was previously active' do
        before { create(:user_badge, user: user, badge_tag: 'voix_presente', active: true, awarded_at: 1.month.ago) }

        it 'deactivates the badge' do
          BadgeService.check_voix_presente(user)
          expect(UserBadge.find_by(user: user, badge_tag: 'voix_presente').active).to be false
        end
      end
    end

    # 5.10 - Badge perdu puis reconquis
    context '5.10 - badge lost then reconquered' do
      let!(:original_awarded_at) { 2.months.ago }

      before do
        create(:user_badge, user: user, badge_tag: 'voix_presente', active: false, awarded_at: original_awarded_at)
        ['2026-W20', '2026-W21', '2026-W22'].each { |w| create(:weekly_activity, user: user, week_iso: w) }
      end

      it 'reactivates the badge' do
        BadgeService.check_voix_presente(user)
        expect(UserBadge.find_by(user: user, badge_tag: 'voix_presente').active).to be true
      end

      it 'preserves the original awarded_at date' do
        BadgeService.check_voix_presente(user)
        expect(UserBadge.find_by(user: user, badge_tag: 'voix_presente').awarded_at)
          .to be_within(1.second).of(original_awarded_at)
      end
    end

    # 5.11 - Idempotence : badge déjà actif, pas de nouvel badge.awarded
    context '5.11 - when badge is already active and still qualifies' do
      before do
        ['2026-W20', '2026-W21', '2026-W22'].each { |w| create(:weekly_activity, user: user, week_iso: w) }
        BadgeService.check_voix_presente(user)
      end

      it 'does not create a duplicate badge record' do
        expect { BadgeService.check_voix_presente(user) }
          .not_to change { UserBadge.where(user: user, badge_tag: 'voix_presente').count }
      end

      it 'preserves the existing awarded_at' do
        existing_awarded_at = UserBadge.find_by(user: user, badge_tag: 'voix_presente').awarded_at
        BadgeService.check_voix_presente(user)
        expect(UserBadge.find_by(user: user, badge_tag: 'voix_presente').awarded_at)
          .to be_within(1.second).of(existing_awarded_at)
      end
    end
  end

  describe '.update_weekly_activity_from' do
    let(:user) { eligible_user }
    let(:neighborhood) { create(:neighborhood) }

    # Reset class-level memoization between tests
    after { BadgeService.instance_variable_set(:@weekly_activity_user_ids, nil) }

    def session_for(u, date: Date.today - 1.week)
      SessionHistory.create!(user_id: u.id, date: date, platform: 'ios')
    end

    def prev_week_range(reference_date)
      reference_date.prev_week.all_week
    end

    # 5.3 - Action = post groupe → WeeklyActivity créée
    context '5.3 - when user posted in a neighborhood during the previous week' do
      let(:reference_date) { Date.today }

      before do
        session_for(user)
        create(:chat_message,
               user: user,
               messageable: neighborhood,
               created_at: prev_week_range(reference_date).first + 1.day)
      end

      it 'creates a WeeklyActivity for the previous week' do
        expect { BadgeService.update_weekly_activity_from(reference_date) }
          .to change { WeeklyActivity.where(user: user).count }.by(1)
      end
    end

    # 5.4 - Action = réaction groupe → WeeklyActivity créée
    # The service checks UserReaction.where(instance_type: 'ChatMessage') on chat messages of a Neighborhood
    context '5.4 - when user reacted on a neighborhood chat message during the previous week' do
      let(:reference_date) { Date.today }
      let(:neighborhood_chat_message) { create(:chat_message, messageable: neighborhood) }

      before do
        session_for(user)
        create(:user_reaction,
               user: user,
               instance: neighborhood_chat_message,
               created_at: prev_week_range(reference_date).first + 1.day)
      end

      it 'creates a WeeklyActivity for the previous week' do
        expect { BadgeService.update_weekly_activity_from(reference_date) }
          .to change { WeeklyActivity.where(user: user).count }.by(1)
      end
    end

    # 5.4bis - Action = réaction hors groupe → pas de WeeklyActivity
    context '5.4bis - when user reacted on a chat message outside a neighborhood' do
      let(:reference_date) { Date.today }
      let(:other_chat_message) { create(:chat_message) }

      before do
        session_for(user)
        create(:user_reaction,
               user: user,
               instance: other_chat_message,
               created_at: prev_week_range(reference_date).first + 1.day)
      end

      it 'does not create a WeeklyActivity for the user' do
        expect { BadgeService.update_weekly_activity_from(reference_date) }
          .not_to change { WeeklyActivity.where(user: user).count }
      end
    end

    # 5.6 - Action hors groupe → pas de WeeklyActivity
    context '5.6 - when user only posted outside a neighborhood context' do
      let(:reference_date) { Date.today }

      before do
        session_for(user)
        create(:chat_message,
               user: user,
               created_at: prev_week_range(reference_date).first + 1.day)
      end

      it 'does not create a WeeklyActivity for the user' do
        expect { BadgeService.update_weekly_activity_from(reference_date) }
          .not_to change { WeeklyActivity.where(user: user).count }
      end
    end

    # 5.7 - Plusieurs actions dans la même semaine comptent comme 1 seule semaine active
    context '5.7 - when user posted multiple times in a neighborhood the same week' do
      let(:reference_date) { Date.today }

      before do
        session_for(user)
        5.times do
          create(:chat_message,
                 user: user,
                 messageable: neighborhood,
                 created_at: prev_week_range(reference_date).first + 1.day)
        end
      end

      it 'creates only 1 WeeklyActivity (not 5)' do
        expect { BadgeService.update_weekly_activity_from(reference_date) }
          .to change { WeeklyActivity.where(user: user).count }.by(1)
      end
    end

    # 5.8 - Utilisateur inactif (pas de session dans les 30 jours) exclu du batch
    context '5.8 - when user has no session in the last month' do
      let(:reference_date) { Date.today }
      let(:inactive_user) { eligible_user }

      before do
        ['2026-W20', '2026-W21', '2026-W22'].each do |w|
          create(:weekly_activity, user: inactive_user, week_iso: w)
        end
        create(:chat_message,
               user: inactive_user,
               messageable: neighborhood,
               created_at: prev_week_range(reference_date).first + 1.day)
      end

      it 'does not create a new WeeklyActivity for the inactive user' do
        expect { BadgeService.update_weekly_activity_from(reference_date) }
          .not_to change { WeeklyActivity.where(user: inactive_user).count }
      end

      it 'does not change the badge status of the inactive user' do
        expect { BadgeService.update_weekly_activity_from(reference_date) }
          .not_to change { UserBadge.where(user: inactive_user).count }
      end
    end

    # 5.12 - Action le dimanche 23h59 rattachée à la semaine ISO courante
    context '5.12 - when user posted on Sunday 23:59 of the previous ISO week' do
      let(:reference_monday) { Date.today.next_week(:monday) }
      let(:sunday_action_time) { (reference_monday - 1.day).end_of_day - 1.minute }
      let(:expected_week_iso) { (reference_monday - 1.week).strftime('%G-W%V') }

      before do
        session_for(user, date: reference_monday - 2.weeks)
        create(:chat_message,
               user: user,
               messageable: neighborhood,
               created_at: sunday_action_time)
      end

      it 'creates a WeeklyActivity for the correct ISO week' do
        BadgeService.update_weekly_activity_from(reference_monday)
        expect(WeeklyActivity.find_by(user: user, week_iso: expected_week_iso)).to be_present
      end
    end
  end

  describe 'Transversal' do
    let(:user) { eligible_user }

    # T.1 - Compte association : non éligible aux badges
    context 'T.1 - when user has an organization goal (association account)' do
      let(:org_user) { create(:public_user, goal: 'organization') }

      it 'does not award bienvenue badge' do
        org_user.update!(
          interest_list: ['activites'],
          involvement_list: ['resources'],
          concern_list: ['sharing_time'],
          availability: { "1" => ["09:00-10:00"] }
        )
        create(:user_reaction, user: org_user)
        expect { BadgeService.check_bienvenue(org_user) }
          .not_to change { UserBadge.count }
      end
    end

    # T.5 - badge_active=false conserve la ligne en base
    context 'T.5 - when badge is deactivated, the row is preserved with awarded_at intact' do
      before do
        create(:user_badge, user: user, badge_tag: 'moteur_rencontres', active: true, awarded_at: 10.days.ago)
        BadgeService.send(:deactivate_badge, user, 'moteur_rencontres')
      end

      it 'does not delete the badge row' do
        expect(UserBadge.where(user: user, badge_tag: 'moteur_rencontres')).to exist
      end

      it 'preserves the awarded_at date' do
        badge = UserBadge.find_by(user: user, badge_tag: 'moteur_rencontres')
        expect(badge.awarded_at).to be_present
      end

      it 'sets active to false' do
        badge = UserBadge.find_by(user: user, badge_tag: 'moteur_rencontres')
        expect(badge.active).to be false
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

      it 'creates the badge with inactive state and metadata when it does not exist yet' do
        BadgeService.send(:update_badge_status, user, 'fidele_papotages', false, { current: 1, target: 3 })
        badge = UserBadge.find_by(user: user, badge_tag: 'fidele_papotages')
        expect(badge).to be_present
        expect(badge.active).to be false
        expect(badge.metadata).to eq({ 'current' => 1, 'target' => 3 })
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

    context 'email delivery' do
      let(:mail_double) { instance_double(ActionMailer::MessageDelivery, deliver_later: nil) }

      it 'sends a congratulations email on first award' do
        expect(MemberMailer).to receive(:congratulations_new_badge)
          .with(user, 'bienvenue', instance_of(ActiveSupport::TimeWithZone))
          .and_return(mail_double)
        BadgeService.send(:award_badge, user, 'bienvenue')
        expect(mail_double).to have_received(:deliver_later)
      end

      it 'does not send email when badge is re-activated (already has awarded_at)' do
        create(:user_badge, user: user, badge_tag: 'bienvenue', active: false, awarded_at: 2.days.ago)
        expect(MemberMailer).not_to receive(:congratulations_new_badge)
        BadgeService.send(:award_badge, user, 'bienvenue')
      end

      it 'does not send email when badge is already active' do
        create(:user_badge, user: user, badge_tag: 'bienvenue', active: true, awarded_at: 1.day.ago)
        expect(MemberMailer).not_to receive(:congratulations_new_badge)
        BadgeService.send(:award_badge, user, 'bienvenue')
      end

      it 'does not send email on first award when notify: false' do
        expect(MemberMailer).not_to receive(:congratulations_new_badge)
        BadgeService.send(:award_badge, user, 'bienvenue', notify: false)
        expect(UserBadge.find_by(user: user, badge_tag: 'bienvenue')).to be_active
      end
    end
  end

  describe '.deactivate_badge (private)' do
    let(:user) { eligible_user }

    it 'sets active to false on an existing badge' do
      create(:user_badge, user: user, badge_tag: 'bienvenue', active: true)
      BadgeService.send(:deactivate_badge, user, 'bienvenue')
      expect(UserBadge.find_by(user: user, badge_tag: 'bienvenue').active).to be false
    end

    it 'creates the badge with active: false when it does not exist yet' do
      expect {
        BadgeService.send(:deactivate_badge, user, 'moteur_rencontres')
      }.to change { UserBadge.where(user: user, badge_tag: 'moteur_rencontres').count }.by(1)

      badge = UserBadge.find_by(user: user, badge_tag: 'moteur_rencontres')
      expect(badge.active).to be false
      expect(badge.awarded_at).to be_nil
    end

    context 'when the badge was previously active' do
      let!(:badge) { create(:user_badge, user: user, badge_tag: 'moteur_rencontres', active: true, awarded_at: 45.days.ago) }

      it 'publishes a badge.deactivated event with the original awarded_at' do
        BadgeService.send(:deactivate_badge, user, 'moteur_rencontres')

        expect(EventBus).to have_received(:publish).with(
          'badge.deactivated',
          hash_including(badge_tag: 'moteur_rencontres', awarded_at: badge.reload.awarded_at)
        )
      end

      it 'passes the user matching the badge owner' do
        BadgeService.send(:deactivate_badge, user, 'moteur_rencontres')

        expect(EventBus).to have_received(:publish).with(
          'badge.deactivated',
          hash_including(user: satisfy { |u| u.id == user.id })
        )
      end

      it 'does not publish a badge.deactivated event when notify: false' do
        BadgeService.send(:deactivate_badge, user, 'moteur_rencontres', notify: false)

        expect(EventBus).not_to have_received(:publish).with('badge.deactivated', anything)
        expect(UserBadge.find_by(user: user, badge_tag: 'moteur_rencontres').active).to be false
      end
    end

    context 'when the badge does not exist yet' do
      it 'does not publish a badge.deactivated event' do
        BadgeService.send(:deactivate_badge, user, 'moteur_rencontres')

        expect(EventBus).not_to have_received(:publish).with('badge.deactivated', anything)
      end
    end

    context 'when the badge is already inactive (idempotence)' do
      before { create(:user_badge, user: user, badge_tag: 'moteur_rencontres', active: false, awarded_at: 45.days.ago) }

      it 'does not publish a badge.deactivated event' do
        BadgeService.send(:deactivate_badge, user, 'moteur_rencontres')

        expect(EventBus).not_to have_received(:publish).with('badge.deactivated', anything)
      end
    end
  end
end
