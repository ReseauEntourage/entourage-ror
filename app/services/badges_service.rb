class BadgesService
  class << self
    def check_all_for_user(user)
      return unless eligible_user?(user)

      check_bienvenue(user)
      check_moteur_rencontres(user)
      check_fidele_papotages(user)
      check_voix_presente(user)
    end

    def eligible_user?(user)
      user.present? && (user.is_ask_for_help? || user.is_offer_help?)
    end

    # Badge n°1 : Bienvenue
    def check_bienvenue(user)
      return unless eligible_user?(user)
      return if UserBadge.exists?(user_id: user.id, badge_tag: 'bienvenue')
      return unless onboarding_completed?(user)
      return unless first_engagement_detected?(user)

      award_badge(user, 'bienvenue')
    end

    # Badge n°2 : Premier lien
    def check_premier_contact(chat_message)
      user = chat_message.user
      return unless eligible_user?(user)
      return if UserBadge.exists?(user_id: user.id, badge_tag: 'premier_contact')

      conversation = chat_message.messageable
      return unless conversation.is_a?(Entourage) && conversation.conversation?

      participants = conversation.members
      return unless participants.count == 2

      return unless participants.all? { |p| p.created_at < 24.hours.ago }

      # Check if both participants have sent at least one non-system message
      # (The current message is already one)
      other_participant = participants.find { |p| p.id != user.id }
      return unless other_participant

      has_other_message = ChatMessage.where(messageable: conversation, user_id: other_participant.id)
                                    .where.not(message_type: ['status_update', 'auto'])
                                    .exists?

      if has_other_message
        award_badge(user, 'premier_contact')
        # Also check for the other participant
        if eligible_user?(other_participant) && !UserBadge.exists?(user_id: other_participant.id, badge_tag: 'premier_contact')
          award_badge(other_participant, 'premier_contact')
        end
      end
    end

    # Badge n°3 : Moteur de rencontres
    def check_moteur_rencontres(user)
      return unless eligible_user?(user)

      count = Outing.where(user_id: user.id)
                    .where('metadata->>\'starts_at\' >= ?', 90.days.ago)
                    .where.not(status: :cancelled)
                    .count

      # Also count as co-host (join_request with role organizer/creator but not being the owner)
      co_hosted_count = JoinRequest.where(user_id: user.id, joinable_type: 'Entourage', status: 'accepted', role: ['organizer', 'creator'])
                                   .joins("JOIN entourages ON entourages.id = join_requests.joinable_id")
                                   .where("entourages.group_type = 'outing'")
                                   .where("entourages.user_id != ?", user.id)
                                   .where("entourages.status != 'cancelled'")
                                   .where("entourages.metadata->>'starts_at' >= ?", 90.days.ago.to_s)
                                   .count

      total_count = count + co_hosted_count
      update_badge_status(user, 'moteur_rencontres', total_count >= 3, { current: total_count, target: 3 })
    end

    # Badge n°4 : Fidèle aux papotages
    def check_fidele_papotages(user)
      return unless eligible_user?(user)

      count = JoinRequest.where(user_id: user.id, joinable_type: 'Entourage', status: 'accepted')
                         .joins("JOIN entourages ON entourages.id = join_requests.joinable_id")
                         .where("entourages.group_type = 'outing'")
                         .where("entourages.online = true AND (entourages.title ilike '%papotage%' OR entourages.sf_category ilike '%papotage%')")
                         .where("entourages.metadata->>'starts_at' >= ?", 90.days.ago.to_s)
                         .count

      update_badge_status(user, 'fidele_papotages', count >= 6, { current: count, target: 6 })
    end

    # Badge n°5 : Vie de groupe
    def check_voix_presente(user)
      return unless eligible_user?(user)

      recent_activities = WeeklyActivity.where(user_id: user.id).recent.limit(4)
      count = recent_activities.count { |a| a.has_group_action }

      should_be_active = count >= 3

      badge = UserBadge.find_by(user_id: user.id, badge_tag: 'voix_presente')

      if should_be_active
        if !badge || !badge.active
          # Only emit event if it was NEVER awarded or reactivation should NOT emit event
          # Requirement says: "Si la condition redevient vraie lors d'un batch suivant, badge_active repasse à true automatiquement sans émettre un nouvel événement badge.awarded"
          is_reactivation = badge.present? && !badge.active
          award_badge(user, 'voix_presente', skip_event: is_reactivation)
        end
      else
        # Reversible only if 2 consecutive weeks without action
        last_two = recent_activities.limit(2)
        if last_two.count == 2 && last_two.all? { |a| !a.has_group_action }
          deactivate_badge(user, 'voix_presente') if badge&.active
        end
      end

      # Update metadata for progress
      badge = UserBadge.find_by(user_id: user.id, badge_tag: 'voix_presente')
      badge&.update(metadata: { current: count, target: 3 })
    end

    def update_weekly_activity
      # Running every Monday morning
      last_week_iso = (Date.today - 1.week).strftime('%G-W%V')

      # Users active in the last 30 days
      user_ids = SessionHistory.where('created_at > ?', 30.days.ago).pluck(:user_id).uniq

      # Cache group/neighborhood IDs outside the loop
      group_ids = Entourage.where(group_type: 'group').pluck(:id)
      neighborhood_ids = Neighborhood.pluck(:id)

      User.where(id: user_ids).find_each do |user|
        has_action = has_group_action_in_week?(user, Date.today - 1.week, group_ids: group_ids, neighborhood_ids: neighborhood_ids)
        WeeklyActivity.create_with(has_group_action: has_action).find_or_create_by(user_id: user.id, week_iso: last_week_iso)

        check_voix_presente(user) if eligible_user?(user)
      end
    end

    private

    def onboarding_completed?(user)
      user.interest_names.present? &&
      user.involvement_names.present? &&
      user.concern_names.present? &&
      user.availability.present?
    end

    def first_engagement_detected?(user)
      ChatMessage.where(user_id: user.id).exists? ||
      JoinRequest.where(user_id: user.id, status: 'accepted').where.not(role: 'creator').exists? ||
      UserBadge.where(user_id: user.id).exists? ||
      UserReaction.where(user_id: user.id).exists?
    end

    def award_badge(user, tag, skip_event: false)
      badge = UserBadge.find_or_initialize_by(user_id: user.id, badge_tag: tag)
      was_active = badge.active
      badge.active = true
      badge.awarded_at ||= Time.now
      badge.save!

      if (!was_active || badge.previously_new_record?) && !skip_event
        Event.track("badge.#{tag}.awarded", user_id: user.id)
      end
    end

    def deactivate_badge(user, tag)
      badge = UserBadge.find_by(user_id: user.id, badge_tag: tag)
      if badge&.active
        badge.update(active: false)
        Event.track("badge.#{tag}.deactivated", user_id: user.id)
      end
    end

    def update_badge_status(user, tag, should_be_active, metadata)
      if should_be_active
        award_badge(user, tag)
      else
        deactivate_badge(user, tag)
      end

      badge = UserBadge.find_by(user_id: user.id, badge_tag: tag)
      badge&.update(metadata: metadata)
    end

    def has_group_action_in_week?(user, date, group_ids: [], neighborhood_ids: [])
      start_date = date.beginning_of_week
      end_date = date.end_of_week

      ChatMessage.where(user_id: user.id, created_at: start_date..end_date)
                 .where("(messageable_type = 'Entourage' AND messageable_id IN (?)) OR (messageable_type = 'Neighborhood' AND messageable_id IN (?))", group_ids, neighborhood_ids)
                 .exists? ||
      UserReaction.where(user_id: user.id, created_at: start_date..end_date)
                  .where("instance_type = 'ChatMessage'")
                  .joins("JOIN chat_messages ON chat_messages.id = user_reactions.instance_id")
                  .where("(chat_messages.messageable_type = 'Entourage' AND chat_messages.messageable_id IN (?)) OR (chat_messages.messageable_type = 'Neighborhood' AND chat_messages.messageable_id IN (?))", group_ids, neighborhood_ids)
                  .exists?
    end
  end
end
