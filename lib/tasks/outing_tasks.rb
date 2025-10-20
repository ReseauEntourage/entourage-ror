module OutingTasks
  PRIVATE_MESSAGE_ORGANISATOR_DAYS = 7
  POST_UPCOMING_DELAY = 2.days
  EMAIL_UPCOMING_DELAY = 7.days
  EMAIL_TO_USER_LOGGED_FROM = 45.days

  class << self
    # send_post_to_upcoming
    def send_post_to_upcoming
      upcoming_outings.pluck(:id).uniq.each do |outing_id|
        outing = Outing.find(outing_id)

        if outing.chat_messages.new(user: outing.user, content: I18n.t("outings.tasks.reminder_content")).save
          outing.update_columns(notification_sent_at: Time.zone.now)
        end
      end
    end

    def upcoming_outings
      Outing
        .active
        .unlimited
        .where(online: false)
        .where(notification_sent_at: nil)
        .upcoming(POST_UPCOMING_DELAY.from_now)
        .with_moderation
        .where('entourage_moderations.moderated_at is not null')
        .joins(:user)
        .where('users.admin = ? OR users.targeting_profile = ?', true, 'team')
        .group('entourages.id')
    end

    # send_private_message_7_days_before
    def send_private_message_7_days_before
      organisator_outings.pluck(:id).uniq.each do |outing_id|
        outing = Outing.find(outing_id)

        return unless moderator = ModerationServices.moderator_for_entourage(outing)

        ConversationService.create_private_message!(
          sender_id: moderator.id,
          recipient_ids: [outing.user_id],
          content: I18n.t(
            "outings.tasks.reminder_7_days_content",
            title: outing.title,
            count: outing.number_of_people,
            neighborhood: outing.user.default_neighborhood.try(:name),
            link: outing.share_url
          )
        )
      end
    end

    def organisator_outings
      Outing
        .active
        .future
        .where(online: false)
        .joins(:user)
        .where("users.admin = false AND (users.targeting_profile NOT IN ('team', 'ambassador') OR users.targeting_profile is null)")
        .in_days(PRIVATE_MESSAGE_ORGANISATOR_DAYS)
    end

    # send_email_as_reminder
    def send_email_as_reminder
      Outing
        .active
        .unlimited
        .where(online: false)
        .tomorrow
        .with_moderation
        .where("entourage_moderations.moderated_at is not null")
        .joins(:user)
        .where("users.admin = true OR users.targeting_profile IN ('team', 'ambassador')")
        .group("entourages.id")
        .each do |outing|
          outing.members.each do |user|
            GroupMailer.event_participation_reminder(outing, user).deliver_later
          end
        end
    end

    # send_email_with_upcoming
    def send_email_with_upcoming
      User
        .validated
        .where("email is not null and email != ''")
        .where('last_sign_in_at > ?', EMAIL_TO_USER_LOGGED_FROM.ago)
        .pluck(:id)
        .each do |user_id|
          OutingTasks.send_email_with_upcoming_to_user(user_id)
        end
    end

    def send_email_with_upcoming_to_user user_id
      user = User.find(user_id)

      action_ids = ActionServices::Finder.new(user, Hash.new).find_all
        .filtered_with_user_profile(user)
        .with_moderation
        .where("entourage_moderations.moderated_at is not null")
        .group("entourages.id")
        .pluck(:id)
        .uniq

      outing_ids = OutingsServices::Finder.new(user, Hash.new).find_all
        .upcoming(EMAIL_UPCOMING_DELAY.from_now)
        .with_moderation
        .where('entourage_moderations.moderated_at is not null')
        .group('entourages.id')
        .pluck(:id)
        .uniq

      return unless action_ids.any? || outing_ids.any?

      MemberMailer.weekly_planning(user, action_ids, outing_ids).deliver_later
    end
  end
end
