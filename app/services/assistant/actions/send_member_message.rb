module Assistant
  module Actions
    # Sends a message in the name of the user to another member, in their private conversation,
    # as the app does: ConversationService finds or builds the one-to-one conversation and
    # ChatServices::ChatMessageBuilder saves the message. The recipient does not agree beforehand
    # and receives the text as if the user had written it: nothing else is sent, in particular not
    # why or through what it was written.
    #
    # A message that starts the conversation is a "first message": it is counted per person
    # (see AssistantAction.first_messages_count).
    class SendMemberMessage < Base
      ACTION_TYPE = 'member.first_message'.freeze

      def initialize user:, recipient:, message:, extra_result: {}
        super(user: user)
        @recipient = recipient
        @content = message
        @extra_result = extra_result
      end

      def call
        require_param!(@content, 'content')
        member = find_recipient!(@recipient)

        participant_ids = [user.id, member.id]
        conversation = ::Entourage.findable.find_by(uuid_v2: ::ConversationService.hash_for_participants(participant_ids))
        first_message = conversation.nil? || !conversation.chat_messages.where(user_id: user.id).exists?
        conversation ||= ::ConversationService.build_conversation(participant_ids: participant_ids, creator_id: user.id)
        join_request = conversation.join_requests.to_a.find { |request| request.user_id == user.id } ||
                       ::JoinRequest.find_by(joinable: conversation, user: user, status: :accepted)

        message = nil
        ::ChatServices::ChatMessageBuilder.new(
          params: { content: @content }, user: user, joinable: conversation, join_request: join_request
        ).create do |on|
          on.success { |created| message = created }
          on.failure { |failed| refuse_with_errors!(failed, 'CANNOT_SEND', 'Could not send the message.') }
        end

        outcome(201, { messageId: message.id, conversationId: message.messageable.uuid_v2, firstMessage: first_message }.merge(@extra_result), message)
      end
    end
  end
end
