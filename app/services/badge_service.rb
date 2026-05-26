class BadgeService
  class << self
    def eligible_user?(user)
      user.present? && !user.anonymous? && (user.is_ask_for_help? || user.is_offer_help?)
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
      return unless chat_message.conversation?

      user = chat_message.user
      return unless eligible_user?(user)
      return if UserBadge.exists?(user_id: user.id, badge_tag: 'premier_contact')

      conversation = chat_message.messageable
      return unless conversation.respond_to?(:members)

      participants = conversation.members
      return unless participants.count == 2
      return unless participants.all? { |p| p.created_at < 24.hours.ago }

      # Check if both participants have sent at least one non-system message
      other_participant = participants.find { |p| p.id != user.id }
      return unless other_participant

      has_other_message = ChatMessage.where(messageable: conversation, user_id: other_participant.id)
                                    .where(message_type: ['text', 'share'])
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
    # This count should be computed when an outing ends, not on outing creation
    # This should count outings with starts_at between 90.days.ago and Time.now
    def check_moteur_rencontres(user)
      return unless eligible_user?(user)

      total_count = Outing.accepted
        .where(user_id: user.id)
        .between(90.days.ago, Time.now)
        .count

      update_badge_status(user, 'moteur_rencontres', total_count >= 3, { current: total_count, target: 3 })
    end

    # Badge n°4 : Fidèle aux papotages
    # Compute the count of papotages the user has participated in (join requests accepted with participate_at not null) in the last 90 days
    def check_fidele_papotages(user)
      return unless eligible_user?(user)

      # Use title as a proxy to avoid N+1 and SQL issues with tags
      count = JoinRequest.accepted
        .where.not(participate_at: nil)
        .where(user_id: user.id, joinable_type: 'Entourage')
        .where(joinable_id: Outing.papotages.between(90.days.ago, Time.now))
        .count

      update_badge_status(user, 'fidele_papotages', count >= 3, { current: count, target: 3 })
    end

    # Badge n°5 : Vie de groupe
    def check_voix_presente(user)
      return unless eligible_user?(user)

      recent_activities = WeeklyActivity.where(user_id: user.id).recent.limit(4)
      count = recent_activities.to_a.count { |a| a.has_group_action }

      should_be_active = count >= 3

      badge = UserBadge.find_by(user_id: user.id, badge_tag: 'voix_presente')

      if should_be_active
        if !badge || !badge.active
          award_badge(user, 'voix_presente')
        end
      else
        # Reversible only if 2 consecutive weeks without action
        last_two = recent_activities.limit(2).to_a
        if last_two.count == 2 && last_two.all? { |a| !a.has_group_action }
          deactivate_badge(user, 'voix_presente') if badge&.active
        end
      end

      # Update metadata for progress
      badge = UserBadge.find_by(user_id: user.id, badge_tag: 'voix_presente')
      badge&.update(metadata: { current: count, target: 3 })
    end

    def update_weekly_activity
      last_week_iso = (Date.today - 1.week).strftime('%G-W%V')

      user_ids = SessionHistory.where('created_at > ?', 30.days.ago).pluck(:user_id).uniq

      User.where(id: user_ids).find_each do |user|
        WeeklyActivity.create_with(
          has_group_action: has_group_action_in_week?(user, Date.today - 1.week)
        ).find_or_create_by(user_id: user.id, week_iso: last_week_iso)

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
      UserReaction.where(user_id: user.id).exists? ||
      JoinRequest.accepted.with_joinable_type(:outing).where(user_id: user.id).exists? ||
      UserResource.where(user_id: user.id, watched: true).exists? ||
      ChatMessage.where(user_id: user.id).exists
    end

    def award_badge(user, tag)
      badge = UserBadge.find_or_initialize_by(user_id: user.id, badge_tag: tag)
      badge.active = true
      badge.awarded_at ||= Time.now
      badge.save!
    end

    def deactivate_badge(user, tag)
      badge = UserBadge.find_by(user_id: user.id, badge_tag: tag)
      if badge&.active
        badge.update(active: false)
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

    def has_group_action_in_week?(user, date)
      start_date = date.beginning_of_week
      end_date = date.end_of_week

      ChatMessage.where(user_id: user.id, created_at: start_date..end_date)
                 .where("messageable_type = 'Neighborhood'")
                 .exists? ||
      UserReaction.where(user_id: user.id, created_at: start_date..end_date)
                  .where("instance_type = 'ChatMessage'")
                  .joins("JOIN chat_messages ON chat_messages.id = user_reactions.instance_id")
                  .where("chat_messages.messageable_type = 'Neighborhood'")
                  .exists?
    end
  end
end
