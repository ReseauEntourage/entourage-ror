module Assistant
  module Actions
    # Passes a message of the user to the Entourage team (safety signal, negative feedback after a
    # meeting, handover in case of distress), through the Slack channel of the signals. The message is
    # the one the user approved, and nothing else than what is needed to call them back.
    #
    # `audience` says who is warned: `referent` (the dedicated contact, named on Slack when there is one
    # that Slack can mention, otherwise the team alone) or `team` (the team alone). `kind` is the nature
    # of the alert; by default `handover` for the referent and `safety_signal` for the team.
    #
    # A failure of Slack never breaks the action: it is reported (Sentry) and the result says
    # `not_delivered`, so that the assistant does not tell the person it was passed on.
    class AlertTeam < Base
      AUDIENCES = %w[referent team].freeze
      KINDS = SlackServices::AssistantAlert::KINDS
      DEFAULT_KINDS = { 'referent' => 'handover', 'team' => 'safety_signal' }.freeze

      def initialize user:, audience:, message:, kind: nil
        super(user: user)
        @audience = audience
        @message = message
        @kind = kind.presence
      end

      def call
        refuse!(400, 'INVALID_PARAMS', "audience must be one of #{AUDIENCES.join(', ')}.") unless AUDIENCES.include?(@audience)
        refuse!(400, 'INVALID_PARAMS', "kind must be one of #{KINDS.join(', ')}.") if @kind && !KINDS.include?(@kind)
        require_param!(@message, 'message')

        kind = @kind || DEFAULT_KINDS.fetch(@audience)
        contact = (::Assistant::ReferentFinder.new(user).find if @audience == 'referent')
        alert = ::SlackServices::AssistantAlert.new(user: user, kind: kind, message: @message, contact: contact)

        outcome(201, { kind: kind, status: deliver(alert) ? 'sent' : 'not_delivered', withContact: alert.contact_mentioned? })
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
