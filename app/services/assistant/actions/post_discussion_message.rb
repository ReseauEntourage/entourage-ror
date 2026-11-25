module Assistant
  module Actions
    # Posts a message in the discussion of an outing in the name of the user (the draft of a
    # presentation), as Api::V1::Outings::ChatMessagesController does: only an accepted member of
    # the outing can write there. The text is untouched.
    class PostDiscussionMessage < Base
      def initialize user:, outing_id:, message:
        super(user: user)
        @outing_id = outing_id
        @message = message
      end

      def call
        require_param!(@message, 'message')
        outing = find_outing!(@outing_id)
        join_request = ::JoinRequest.find_by(joinable: outing, user: user, status: :accepted)
        refuse!(403, 'NOT_A_MEMBER', 'The user is not registered to this outing.') unless join_request

        posted = nil
        ::ChatServices::ChatMessageBuilder.new(
          params: { content: @message }, user: user, joinable: outing, join_request: join_request
        ).create do |on|
          on.success { |created| posted = created }
          on.failure { |failed| refuse_with_errors!(failed, 'CANNOT_SEND', 'Could not post the message.') }
        end

        outcome(201, { messageId: posted.id, outingId: outing.uuid_v2 }, posted)
      end
    end
  end
end
