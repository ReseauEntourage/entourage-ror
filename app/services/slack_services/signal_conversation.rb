module SlackServices
  class SignalConversation < Notifier
    def initialize conversation:, reporting_user:, signals:, message:
      @conversation = conversation
      @reporting_user = find_user(reporting_user)
      @signals = signals
      @message = message
    end

    def env
      ENV['SLACK_SIGNAL']
    end

    def payload
      {
        text: "<@#{slack_moderator_id(interlocutor)}> ou team modération (département : #{departement(interlocutor) || 'n/a'}) pouvez-vous vérifier cette conversation ?",
        attachments: [
          {
            text: "Conversation : #{@conversation.title} #{link_to_conversation(@conversation)}"
          },
          {
            text: "Signalée par : #{@reporting_user.full_name} #{link_to_user(@reporting_user.id)}"
          },
          {
            text: "Catégories #{@signals.join(', ')}, message : #{@message}"
          },
        ]
      }
    end

    def payload_adds
      {
        username: "Signalement d'une conversation",
        channel: webhook('channel'),
      }
    end

    private

    def interlocutor
      @interlocutor ||= @conversation.interlocutor_of(@reporting_user)
    end
  end
end
