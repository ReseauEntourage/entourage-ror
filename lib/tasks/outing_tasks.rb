module OutingTasks
  REMINDER_CONTENT = "Cet événement arrive à grands pas ! Si vous êtes toujours intéressé.e pour participer, merci de commenter “Je participe” en commentaire de ce message."

  POST_UPCOMING_DELAY = 2.days
  EMAIL_UPCOMING_DELAY = 7.days
  EMAIL_TO_USER_LOGGED_FROM = 45.days

  class << self
    # send_post_to_upcoming
    def send_post_to_upcoming
      upcoming_outings.pluck(:id).uniq.each do |outing_id|
        outing = Outing.find(outing_id)

        if outing.chat_messages.new(user: outing.user, content: REMINDER_CONTENT).save
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
        .where("entourage_moderations.moderated_at is not null")
        .joins(:user)
        .where("users.admin = ? OR users.targeting_profile = ?", true, 'team')
        .group("entourages.id")
    end

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
          GroupMailer.event_participation_reminder(outing).deliver_later
        end
    end

    # send_email_with_upcoming
    def send_email_with_upcoming
      User
        .validated
        .where("email is not null and email != ''")
        .where("last_sign_in_at > ?", EMAIL_TO_USER_LOGGED_FROM.ago)
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
        .where("entourage_moderations.moderated_at is not null")
        .group("entourages.id")
        .pluck(:id)
        .uniq

      return unless action_ids.any? || outing_ids.any?

      MemberMailer.weekly_planning(user, action_ids, outing_ids).deliver_later
    end
  end
end
