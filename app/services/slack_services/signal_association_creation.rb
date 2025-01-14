module SlackServices
  class SignalAssociationCreation < Notifier
    def initialize user:
      @user = user
    end

    def env
      ENV['SLACK_SIGNAL']
    end

    def payload
      {
        text: "<@#{slack_moderator_id(@user)}> ou team modération (département : #{departement(@user) || 'n/a'}). Un utilisateur a créé un compte association",
        attachments: [{
          text: "Compte créé : #{@user.full_name}, #{link_to_user @user.id} (#{@user.phone}, #{@user.email})"
        }]
      }
    end

    def payload_adds
      {
        username: "Création d’un compte association",
        channel: webhook('channel'),
      }
    end
  end
end
