module Assistant
  module Actions
    # Base of the actions that the assistant asks on behalf of a user. An action reuses the services
    # of the app with the user's own model: no validation is skipped, nothing is done that the user
    # could not do in the app. It returns an ActionRunner::Outcome (identifiers and statuses only,
    # never a text) or refuses with ActionRunner::Refusal.
    class Base
      def initialize user:
        @user = user
      end

      private

      attr_reader :user

      def refuse! status, code, message, reasons = nil
        raise ActionRunner::Refusal.new(status: status, code: code, message: message, reasons: reasons)
      end

      def outcome status, body, subject = nil
        ActionRunner::Outcome.new(status: status, body: body, subject: subject)
      end

      def require_param! value, name
        refuse!(400, 'INVALID_PARAMS', "#{name} is required.") if value.blank?
        value
      end

      # An outing that the app shows to this user, found by its uuid or id.
      def find_outing! identifier
        require_param!(identifier, 'outing id')
        ::Outing.for_user(user).find_by_id_or_uuid(identifier.to_s) || refuse!(404, 'NOT_FOUND', 'Outing not found.')
      end

      # A member that the user can write to: not themselves, not deleted, blocked or anonymized, and
      # with whom there is no block in either direction (the app refuses the message too, see
      # ChatMessage#validate_private_conversation_is_not_blocked!). A block is answered as an unknown
      # member, so that nothing reveals it.
      def find_recipient! recipient
        member = recipient.is_a?(::User) ? recipient : $server_community.users.find_by(uuid: recipient.to_s)
        usable = member && member.id != user.id && !member.deleted && !member.blocked? && !member.anonymized?
        blocked = usable && ::UserBlockedUser.with_users([user.id, member.id]).exists?
        refuse!(404, 'RECIPIENT_UNAVAILABLE', 'This member cannot be written to.') if !usable || blocked

        member
      end

      def refuse_with_errors! record, code, message
        refuse!(400, code, message, record.errors.full_messages)
      end
    end
  end
end
