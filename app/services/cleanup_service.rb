class CleanupService
  def self.send_slack_alert tour_ids
    return if ENV['SLACK_WEBHOOK_URL'].blank?

    Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL']).ping(
      text: "*Le compte-rendu de maraude n'a pas été délivré* après 48 h " \
            "pour les maraudes suivantes : _#{tour_ids.to_sentence}_.\n" \
            "Les données n'ont donc pas été effacées.",
      channel: '#mailjet-errors',
      username: 'Maraudes',
      icon_emoji: ':memo:'
    )
  end
end
