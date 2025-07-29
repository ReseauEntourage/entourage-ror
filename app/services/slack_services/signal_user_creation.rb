module SlackServices
  class SignalUserCreation < Notifier
    def initialize user:, blocked_user_ids:
      @user = user
      @blocked_user_ids = blocked_user_ids
    end

    def env
      ENV['SLACK_SIGNAL']
    end

    def payload
      {
        text: "<@#{slack_moderator_id(@user)}> ou team modération (département : #{departement(@user) || 'n/a'}). Un utilisateur a créé un compte avec le même email qu'un compte bloqué. Merci de vérifier cet utilisateur.",
        attachments: [{
          text: "Compte créé : #{@user.full_name}, #{link_to_user @user.id}"
        }] + @blocked_user_ids.map { |blocked_user_id|
          { text: "Utilisateur bloqué : #{link_to_user blocked_user_id }"}
        }
      }
    end

    def payload_adds
      {
        username: 'Nouveau compte avec email bloqué',
        channel: webhook('channel'),
      }
    end
  end
end
