module TourService
  def self.send_reopened_tour_slack_alert tour:, api_key:
    return if ENV['SLACK_WEBHOOK_URL'].blank?

    user = tour.user
    key_infos = Api::ApplicationKey.new(api_key: api_key).key_infos
    Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL']).ping(
      channel: channel,
      username: 'Maraudes',
      icon_emoji: ':memo:',
      attachments: [
        {
          color: :danger,
          title:"Une rencontre a été ajoutée à une maraude déjà fermée.",
          text: "Le compte-rendu de cette maraude a déjà été envoyé et _l'utilisateur "\
                "risque de perdre les données_."
        },
        {
          fields: [
            {title: 'Utilisateur', short: true,
             value: "<https://admin.entourage.social/users/#{user.id}|#{UserService.full_name(user)}>"},
            {title: 'Association', short: true,
             value: "<https://admin.entourage.social/organizations/#{user.organization_id}/edit|#{user.organization.name}>"},
            {title: 'Application', short: true,
             value: "#{key_infos[:device]} #{key_infos[:version]}"},
            {title: 'Maraude', short: true,
             value: tour.id},
          ]
        },
        {
          text: "Ce problème est dû à un bug connu dans nos applications mobiles.\n"\
                "_La maraude a été ré-ouverte, et un nouveau compte-rendu devrait être "\
                "envoyé_, mais il serait préférable de contacter l'utilisateur pour "\
                "s'assurer qu'une nouvelle maraude est créée."
        }
      ]
    )
  end

  def self.channel
    return '#associations' if EnvironmentHelper.production?

    '#backenddev'
  end
end
