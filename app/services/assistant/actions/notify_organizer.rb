module Assistant
  module Actions
    # Warns the organizer of an outing in the name of the user (first time, question about the
    # sheet, safety signal): a private message to the organizer, with the mechanism of the app
    # (see SendMemberMessage). The text is the one the person approved.
    class NotifyOrganizer < Base
      def initialize user:, outing_id:, message:
        super(user: user)
        @outing_id = outing_id
        @message = message
      end

      def call
        outing = find_outing!(@outing_id)
        refuse!(400, 'INVALID_PARAMS', 'The user is the organizer.') if outing.user_id == user.id

        SendMemberMessage.new(user: user, recipient: outing.user, message: @message, extra_result: { outingId: outing.uuid_v2 }).call
      end
    end
  end
end
