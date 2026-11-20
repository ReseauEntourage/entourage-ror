module Assistant
  module Actions
    # Passes a message of the user to the Entourage team (safety signal, negative feedback after a
    # meeting, handover in case of distress), through the Slack channel of the signals. The message is
    # the one the user approved, and nothing else than what is needed to call them back.
    #
    # A failure of Slack never breaks the action: it is reported (Sentry) and the result says
    # `not_delivered`, so that the assistant does not tell the person it was passed on.
    class AlertTeam < Base
      KINDS = SlackServices::AssistantAlert::KINDS

      def initialize user:, kind:, content:
        super(user: user)
        @kind = kind
        @content = content
      end

      def call
        refuse!(400, 'INVALID_PARAMS', "kind must be one of #{KINDS.join(', ')}.") unless KINDS.include?(@kind)
        require_param!(@content, 'content')

        alert = ::SlackServices::AssistantAlert.new(
          user: user, kind: @kind, message: @content, contact: ::Assistant::ReferentFinder.new(user).find
        )

        outcome(201, { kind: @kind, status: deliver(alert) ? 'sent' : 'not_delivered', withContact: alert.contact_mentioned? })
      end

      private

      def deliver alert
        alert.notify
        true
      rescue StandardError => e
        Sentry.capture_exception(e)
        false
      end
    end
  end
end
