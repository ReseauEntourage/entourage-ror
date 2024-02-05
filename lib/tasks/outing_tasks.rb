module OutingTasks
  REMINDER_CONTENT = "Cet événement arrive à grands pas ! Si vous êtes toujours intéressé.e pour participer, merci de commenter “Je participe” en commentaire de ce message. Nous reviendrons vers vous pour vous confirmer votre inscription."

  UPCOMING_DELAY = 2.days

  class << self
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
        .where(notification_sent_at: nil)
        .upcoming(UPCOMING_DELAY.from_now)
        .joins(:user)
        .where("users.admin = ? OR users.targeting_profile = ?", true, 'team')
    end
  end
end
