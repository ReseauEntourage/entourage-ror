module Assistant
  module Actions
    # Warns the organizer of an outing in the name of the user (first time, question about the
    # sheet, safety signal): a private message to the organizer, with the mechanism of the app
    # (see SendMemberMessage).
    class NotifyOrganizer < Base
      KINDS = %w[first_time question safety_signal].freeze

      def initialize user:, outing_id:, kind:, content:
        super(user: user)
        @outing_id = outing_id
        @kind = kind
        @content = content
      end

      def call
        refuse!(400, 'INVALID_PARAMS', "kind must be one of #{KINDS.join(', ')}.") unless KINDS.include?(@kind)
        outing = find_outing!(@outing_id)
        refuse!(400, 'INVALID_PARAMS', 'The user is the organizer.') if outing.user_id == user.id

        SendMemberMessage.new(user: user, recipient: outing.user, content: @content, extra_result: { outingId: outing.uuid_v2, kind: @kind }).call
      end
    end
  end
end
