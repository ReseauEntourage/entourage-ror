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
        text: "<@#{slack_moderator_id(@user)}> ou team modération (département : #{departement(@user) || 'n/a'}). Un utilisateur a créé un compte association. Au besoin, merci de créer l'association correspondante et/ou d'associer l'utilisateur à cette association sur le backoffice.",
        attachments: [{
          text: "Compte créé : #{@user.full_name}, #{link_to_user @user.id}"
        }]
      }
    end

    def payload_adds
      {
        username: "Nouvel utilisateur association",
        channel: webhook('channel'),
      }
    end
  end
end
