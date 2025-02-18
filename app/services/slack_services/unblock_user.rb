module SlackServices
  class UnblockUser < Notifier
    def initialize user_id:
      @user = User.find_by_id(user_id)
    end

    def env
      ENV['SLACK_UNBLOCK_WEBHOOK']
    end

    def payload
      return {} unless @user

      {
        text: "<@#{slack_moderator_id(@user)}> ou team modération (département : #{departement(@user) || 'n/a'}) Le blocage temporaire de l'utilisateur #{@user.full_name} arrive à échéance aujourd'hui, #{I18n.l @user.unblock_at if @user.unblock_at}",
        attachments: [
          {
            callback_id: [:user_unblock, @user.id].join(':'),
            fallback: "",
            actions: [
              {
                text:  "Débloquer",
                type:  :button,
                style: :primary,
                name:  :action,
                value: :unblock,
                confirm: {
                  title:        "Débloquer cet utilisateur ?",
                  text:         "Il pourra de nouveau accéder à l'application Entourage",
                  ok_text:      "Oui",
                  dismiss_text: "Non"
                }
              },
              {

                text: "Afficher",
                type: :button,
                url: link_to_user(@user.id)
              }
            ]
          }
        ]
      }
    end

    def payload_adds
      {
        username: webhook('username'),
        channel: webhook('channel'),
      }
    end

    # used by Admin::SlackController.authenticate_slack_user_unblock! to authenticate webhook
    def self.webhook field
      SlackServices::UnblockUser.new(user_id: nil).webhook(field)
    end
  end
end
