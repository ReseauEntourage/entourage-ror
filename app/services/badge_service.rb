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
    def check_moteur_rencontres(user)
      total_count = Outing.accepted
        .where(user_id: user.id)
        .where(created_at: 90.days.ago..Time.now)
        .count

      update_badge_status(user, 'moteur_rencontres', total_count >= 3, { current: total_count, target: 3 })
    end

    # Badge n°4 : Fidèle aux papotages
    # Compute the count of papotages the user has participated in (join requests accepted with participate_at not null) in the last 90 days
    def check_fidele_papotages(user)
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
      count = WeeklyActivity
        .where(user_id: user.id)
        .recent
        .limit(4)
        .count

      update_badge_status(user, 'voix_presente', count >= 3, { current: count, target: 3 })
    end

    def update_weekly_activity
      update_weekly_activity_from(Date.today)
    end

    def update_weekly_activity_from date
      user_ids = SessionHistory
        .where('date between ? and ?', date - 1.month, date)
        .group(:user_id)
        .pluck(:user_id)

      previous_week_iso = (date - 1.week).strftime('%G-W%V')

      weekly_activity_user_ids = weekly_activity_user_ids_for_time_range(date.prev_week.all_week)

      User.where(id: user_ids).find_each do |user|
        if weekly_activity_user_ids.include?(user.id)
          WeeklyActivity.find_or_create_by(user_id: user.id, week_iso: previous_week_iso)
        end

        check_voix_presente(user)
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
      UsersResource.where(user_id: user.id, watched: true).exists? ||
      ChatMessage.where(user_id: user.id).exists?
    end

    def award_badge(user, tag)
      badge = UserBadge.find_or_initialize_by(user_id: user.id, badge_tag: tag)

      return if badge.persisted? && badge.active

      badge.active = true
      badge.awarded_at ||= Time.now
      badge.save!
    end

    def deactivate_badge(user, tag)
      return unless badge = UserBadge.find_by(user_id: user.id, badge_tag: tag)

      badge.update(active: false)
    end

    def update_badge_status(user, tag, should_be_active, metadata)
      if should_be_active
        award_badge(user, tag)
      else
        deactivate_badge(user, tag)
      end

      return unless badge = UserBadge.find_by(user_id: user.id, badge_tag: tag)

      badge.update(metadata: metadata)
    end

    # @caution memoization implies that this method should be called from a job only
    def weekly_activity_user_ids_for_time_range(time_range)
      @weekly_activity_user_ids ||= begin
        message_users = ChatMessage
          .where(messageable_type: 'Neighborhood', created_at: time_range)
          .select(:user_id)

        reaction_users = UserReaction
          .where(instance_type: 'Neighborhood', created_at: time_range)
          .select(:user_id)

        ActiveRecord::Base.connection.select_values(
          "(#{message_users.to_sql}) UNION (#{reaction_users.to_sql})"
        )
      end
    end
  end
end
