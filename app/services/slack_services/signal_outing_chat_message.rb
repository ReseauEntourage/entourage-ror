module SlackServices
  class SignalOutingChatMessage < Notifier
    def initialize chat_message:, reporting_user:, signals:, message:
      @reporting_user = find_user(reporting_user)

      @chat_message = chat_message
      @outing = chat_message.messageable
      @signals = signals
      @message = message
      @content = chat_message.content
    end

    def env
      ENV['SLACK_SIGNAL_OUTING_WEBHOOK']
    end

    def payload
      {
        text: "<@#{slack_moderator_id(@outing)}> ou team modération (département : #{departement(@outing) || 'n/a'}) pouvez-vous vérifier le message de ce événement ?",
        attachments: [
          {
            text: "Événement : #{@outing.title} #{link_to_group(@outing)}"
          },
          {
            text: "Signalé par : #{@reporting_user.full_name} #{link_to_user(@reporting_user.id)}"
          },
          {
            text: "Message signalé : #{@content}"
          },
          {
            text: "Catégorie #{@signals}, message : #{@message}"
          },
        ]
      }
    end

    def payload_adds
      {
        username: webhook('username'),
        channel: webhook('channel'),
      }
    end
  end
end
