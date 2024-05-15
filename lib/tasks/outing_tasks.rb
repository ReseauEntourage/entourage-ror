module OutingTasks
  REMINDER_CONTENT = "Cet événement arrive à grands pas ! Si vous êtes toujours intéressé.e pour participer, merci de commenter “Je participe” en commentaire de ce message. Nous reviendrons vers vous pour vous confirmer votre inscription."

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
        .joins(:user)
        .where("users.admin = ? OR users.targeting_profile = ?", true, 'team')
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

      return unless (outing_ids = OutingsServices::Finder.new(user, {}).find_all
        .upcoming(EMAIL_UPCOMING_DELAY.from_now)
        .pluck(:id)
        .uniq
      ).any?

      MemberMailer.weekly_planning(user, outing_ids).deliver_later
    end
  end
end
