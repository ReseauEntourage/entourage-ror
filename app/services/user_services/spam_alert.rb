module UserServices
  class SpamAlert
    attr_reader :spammer, :callback

    def initialize spammer:
      @spammer = spammer
      @callback = Callback.new
    end

    def alert! moderator, message
      yield @callback if block_given?

      UserHistory.create!({
        user_id: @spammer.id,
        updater_id: moderator.id,
        kind: 'spam-alert',
        metadata: {
          message: message
        }
      })

      # @warning should be renamed to ChatMessagesPrivateJob (EN-4011)
      ChatMessagesJob.perform_later(
        moderator.id,
        User.in_conversation_with(@spammer.id).pluck(:id),
        message
      )

      @callback.on_success.try(:call, @spammer)
    rescue ActiveRecord::RecordInvalid => e
      @callback.on_failure.try(:call, e)
    end
  end
end
