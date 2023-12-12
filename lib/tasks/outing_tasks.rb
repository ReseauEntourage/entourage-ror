module OutingTasks
  REMINDER_CONTENT = "Cet événement arrive à grands pas ! Si vous êtes toujours intéressé.e pour participer, merci de commenter “Je participe” en commentaire de ce message. Nous reviendrons vers vous pour vous confirmer votre inscription."

  class << self
    def send_post_to_upcoming
      upcoming_outings.pluck(:id).each do |outing_id|
        outing = Outing.find(outing_id)

        if outing.chat_messages.new(user: outing.user, content: REMINDER_CONTENT).save
          outing.update(notification_sent_at: Time.zone.now)
        end
      end
    end

    def upcoming_outings
      Outing.active.where(notification_sent_at: nil).upcoming(1.year.from_now)
    end
  end
end
