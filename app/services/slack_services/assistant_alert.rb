module SlackServices
  # A message that the AI assistant passes to the team in the name of a user: safety signal, negative
  # feedback after a meeting, handover in case of distress. Modelled on SignalUser (same channel,
  # same attachments), without a reported user: the person is the one who writes, and the team can
  # find them from the link to their profile.
  #
  # With a dedicated contact, the message mentions them; without one, the team is warned alone.
  class AssistantAlert < Notifier
    KINDS = %w[safety_signal negative_feedback handover].freeze

    LABELS = {
      'safety_signal' => 'Signal de sécurité transmis par l’assistant',
      'negative_feedback' => 'Retour négatif après une rencontre, transmis par l’assistant',
      'handover' => 'Passation demandée par l’assistant (personne en détresse)'
    }.freeze

    def initialize user:, kind:, message:, contact: nil
      @user = user
      @kind = kind
      @message = message
      @contact = contact
    end

    def env
      ENV['SLACK_SIGNAL']
    end

    def payload
      {
        text: "#{mention} — #{LABELS.fetch(@kind)} (département : #{departement(@user) || 'n/a'}). Pouvez-vous rappeler cette personne ?",
        attachments: [
          { text: "Personne : #{@user.full_name} #{link_to_user(@user.id)}" },
          { text: "Message : #{@message}" },
          { text: "Catégorie : #{@kind}" }
        ]
      }
    end

    def payload_adds
      {
        username: 'Alerte de l’assistant',
        channel: webhook('channel')
      }
    end

    # Whether the dedicated contact is named in the message: only when one was given (the assistant
    # warns the referent) and the team can mention them on Slack.
    def contact_mentioned?
      @contact&.slack_id.present?
    end

    private

    def mention
      return 'Team modération' unless contact_mentioned?

      "<@#{@contact.slack_id}> ou team modération"
    end
  end
end
