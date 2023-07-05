module SlackServices
  class SignalSpam < Notifier
    def initialize spam_user:, content:
      @spam_user = spam_user
      @content = content
    end

    def env
      ENV['SLACK_SIGNAL']
    end

    def payload
      {
        text: "<@#{slack_moderator_id(@spam_user)}> ou team modération (département : #{departement(@spam_user) || 'n/a'}) pouvez-vous vérifier cet utilisateur ?",
        attachments: [
          {
            text: "Utilisateur signalé : #{@spam_user.full_name} #{link_to_user(@spam_user.id)}"
          },
          {
            text: "Spam : #{@content}"
          },
        ]
      }
    end

    def payload_adds
      {
        username: "Détection auto d'un spam",
        channel: webhook('channel'),
      }
    end
  end
end
