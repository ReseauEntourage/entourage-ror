module Onboarding
  module ChatMessagesService
    MIN_DELAY = 2.hours
    ACTIVITY_WINDOW = '09:00'..'18:30'

    def self.welcome_messages_for user
      first_name = user.first_name
        .scan(/[[:alpha:]]+|[^[:alpha:]]+/)
        .map(&:capitalize)
        .join
        .strip

      messages = []
      messages.push <<-MESSAGE.strip_heredoc.strip
        Bonjour #{first_name},
        Bienvenue sur le réseau Entourage !
        Je m’appelle Guillaume, je m’occupe de l’accompagnement : je réponds à vos questions, je vous oriente, et veille au respect de la charte éthique de l’association.
        De belles actions n’attendent que vous sur le réseau... qui promettent de belles rencontres ! Et si vous avez la moindre question, contactez moi par message ou par téléphone au 07 68 03 73 48
        À bientôt !
      MESSAGE

      messages.push <<-MESSAGE.strip_heredoc.strip
        Ah oui, j’oubliais, voici les autres outils à votre dispo👌 :
        - “Simple comme Bonjour”, 🎥 un guide qui vous donne des conseils concrets pour mieux comprendre le monde de la rue : www.simplecommebonjour.org
        - Un annuaire des structures solidaires directement dans l’app📱: bains-douches, distributions alimentaires...
        Pas mal, n’est-ce pas ?
      MESSAGE

      messages
    end

    def self.deliver_welcome_message
      now = Time.zone.now
      return unless now.strftime('%H:%M').in?(ACTIVITY_WINDOW)

      author = User.find_by(email: "guillaume@entourage.social",
                            community: :entourage, admin: true)

      user_ids = User
        .where(community: :entourage, deleted: false)
        .with_event('onboarding.profile.first_name.entered', :trigger_events)
        .without_event('onboarding.chat_messages.welcome.sent')
        .without_event('onboarding.chat_messages.welcome.skipped')
        .where("trigger_events.created_at <= ?", MIN_DELAY.ago)
        .pluck(:id)

      User.where(id: user_ids).find_each do |user|
        begin
          Raven.user_context(id: user&.id)

          participant_ids = [author.id, user.id]

          conversation_uuid = ConversationService.hash_for_participants(participant_ids, validated: false)
          conversation = Entourage.find_by(uuid_v2: conversation_uuid)

          if conversation
            join_request = JoinRequest.find_by(joinable: conversation, user: author, status: :accepted)
            chat_message_exists = conversation.chat_messages.where(message_type: :text).exists?
          else
            conversation = ConversationService.build_conversation(participant_ids: participant_ids)
            join_request = conversation.join_requests.to_a.find { |r| r.user_id == author.id }
            chat_message_exists = false
          end

          if chat_message_exists
            Event.track('onboarding.chat_messages.welcome.skipped', user_id: user.id)
            return
          end

          messages = welcome_messages_for(user)

          messages.each do |message|
            builder = ChatServices::ChatMessageBuilder.new(
              user: author,
              joinable: conversation,
              join_request: join_request,
              params: {content: message}
            )

            builder.create do |on|
              on.success do
                Event.track('onboarding.chat_messages.welcome.sent', user_id: user.id)
              end

              on.failure do |message|
                raise ActiveRecord::RecordNotSaved.new("Failed to save the record", message)
              end
            end
          end

        rescue => e
          Raven.capture_exception(e)
        end
      end
    end
  end
end
