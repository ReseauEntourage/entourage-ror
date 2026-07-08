class BadgeService
  class << self
    # Badge n°1 : Bienvenue
    def check_bienvenue(user, notify: true)
      return if UserBadge.exists?(user_id: user.id, badge_tag: 'bienvenue')
      return unless onboarding_completed?(user)
      return unless first_engagement_detected?(user)

      award_badge(user, 'bienvenue', notify: notify)
    end

    # Badge n°2 : Premier lien
    def check_premier_contact(chat_message, notify: true)
      return unless chat_message.conversation?

      user = chat_message.user
      conversation = chat_message.messageable
      return unless conversation.respond_to?(:members)

      participants = conversation.members
      return unless participants.count == 2
      return unless participants.all? { |p| p.created_at < 24.hours.ago }

      other_participant = participants.find { |p| p.id != user.id }
      return unless other_participant

      has_other_message = ChatMessage.where(messageable: conversation, user_id: other_participant.id)
                                    .where(message_type: ['text', 'share'])
                                    .where(created_at: 90.days.ago..Time.now)
                                    .exists?

      return unless has_other_message

      award_badge(user, 'premier_contact', notify: notify)
      award_badge(other_participant, 'premier_contact', notify: notify)
    end

    # Badge n°3 : Moteur de rencontres
    def check_moteur_rencontres(user, notify: true)
      total_count = Outing.accepted
        .where(user_id: user.id)
        .where(created_at: 90.days.ago..Time.now)
        .count

      update_badge_status(user, 'moteur_rencontres', total_count >= 3, { current: total_count, target: 3 }, notify: notify)
    end

    # Badge n°4 : Fidèle aux papotages
    # Compute the count of papotages the user has participated in (join requests accepted with participate_at not null) in the last 90 days
    def check_fidele_papotages(user, notify: true)
      # Use title as a proxy to avoid N+1 and SQL issues with tags
      count = JoinRequest.accepted
        .where.not(participate_at: nil)
        .where(user_id: user.id, joinable_type: 'Entourage')
        .where(joinable_id: Outing.papotages.between(90.days.ago, Time.now))
        .count

      update_badge_status(user, 'fidele_papotages', count >= 3, { current: count, target: 3 }, notify: notify)
    end

    # Badge n°5 : Vie de groupe
    def check_voix_presente(user, notify: true)
      count = WeeklyActivity
        .where(user_id: user.id)
        .recent
        .limit(4)
        .count

      update_badge_status(user, 'voix_presente', count >= 3, { current: count, target: 3 }, notify: notify)
    end

    def update_weekly_activity
      update_weekly_activity_from(Date.today)
    end

    def update_weekly_activity_from date, notify: true
      user_ids = SessionHistory
        .where('date between ? and ?', date - 1.month, date)
        .group(:user_id)
        .pluck(:user_id)

      previous_week_iso = (date - 1.week).strftime('%G-W%V')

      # Use Time range (not Date range) to include actions up to Sunday 23:59:59
      prev_week_start = date.prev_week.beginning_of_week.beginning_of_day
      prev_week_end   = date.prev_week.end_of_week.end_of_day
      weekly_activity_user_ids = weekly_activity_user_ids_for_time_range(prev_week_start..prev_week_end)

      User.where(id: user_ids).find_each do |user|
        if weekly_activity_user_ids.include?(user.id)
          WeeklyActivity.find_or_create_by(user_id: user.id, week_iso: previous_week_iso)
        end

        check_voix_presente(user, notify: notify)
      end
    end

    private

    def onboarding_completed?(user)
      return false unless user.interest_names.present? && user.involvement_names.present?

      # team
      return true if user.team?

      # ask_for_help, offer_help
      return user.concern_names.present? && user.availability.present? if user.is_ask_for_help? || user.is_offer_help?

      # association
      if user.association?
        return false unless user.partner.present?
        return user.partner.image_url.present? && user.partner.description.present?
      end

      true
    end

    def first_engagement_detected?(user)
      UserReaction.where(user_id: user.id).exists? ||
      JoinRequest.accepted.with_joinable_type(:outing).where(user_id: user.id).exists? ||
      UsersResource.where(user_id: user.id, watched: true).exists? ||
      ChatMessage.where(user_id: user.id).exists?
    end

    def award_badge(user, tag, notify: true)
      badge = UserBadge.find_or_initialize_by(user_id: user.id, badge_tag: tag)

      return if badge.persisted? && badge.active

      is_new_award = badge.awarded_at.nil?
      badge.active = true
      badge.awarded_at ||= Time.now
      badge.save!

      MemberMailer.congratulations_new_badge(user, tag, badge.awarded_at).deliver_later if is_new_award && notify
    end

    def deactivate_badge(user, tag, notify: true)
      badge = UserBadge.find_or_initialize_by(user_id: user.id, badge_tag: tag)
      was_active = badge.active
      awarded_at = badge.awarded_at

      badge.update(active: false)

      if was_active && awarded_at.present? && notify
        EventBus.publish("badge.deactivated", user: user, badge_tag: tag, awarded_at: awarded_at, deactivated_at: Time.now)
      end
    end

    def update_badge_status(user, tag, should_be_active, metadata, notify: true)
      if should_be_active
        award_badge(user, tag, notify: notify)
      else
        deactivate_badge(user, tag, notify: notify)
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

        # Driven from user_reactions (already bounded by time_range) and joined to
        # chat_messages by primary key, so we never scan the full chat_messages table.
        reaction_users = UserReaction
          .joins("INNER JOIN chat_messages ON chat_messages.id = user_reactions.instance_id")
          .where(user_reactions: { instance_type: 'ChatMessage', created_at: time_range })
          .where(chat_messages: { messageable_type: 'Neighborhood' })
          .select('user_reactions.user_id')

        ActiveRecord::Base.connection.select_values(
          "(#{message_users.to_sql}) UNION (#{reaction_users.to_sql})"
        )
      end
    end
  end
end
