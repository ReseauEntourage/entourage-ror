module ChatServices
  class ChatMessageBuilder
    def initialize(params:, user:, joinable:, join_request:)
      @callback = ChatServices::ChatMessageBuilderCallback.new
      @user = user
      @joinable = joinable
      @message = joinable.chat_messages.new(params)
      @message.user = user
      @join_request = join_request
    end

    def create
      yield callback if block_given?

      return callback.on_freezed_tour.try(:call, message) if joinable.freezed?

      if message.message_type == 'status_update'
        message.errors.add(:message_type, :inclusion)
        return callback.on_failure.try(:call, message)
      end

      success = false
      if joinable.new_record?
        success = begin
          ApplicationRecord.connection.transaction do
            join_requests = joinable.join_requests.to_a
            joinable.join_requests = []
            joinable.chat_messages = []
            joinable.instance_variable_set(:@readonly, false)

            # we set the uuid manually instead of updating it gradually at each
            # join_request. see next comment.
            joinable.uuid_v2 = ConversationService.hash_for_participants(
              join_requests.map(&:user_id), validated: false)

            joinable.save!
            join_requests.each do |join_request|
              join_request.joinable = joinable

              # if we update the UUID at each user, one of the intermediary
              # conversations (e.g. first user with itself) may already exist
              # and cause an error.
              join_request.skip_conversation_uuid_update!

              join_request.save!
            end
            message.messageable = joinable
            message.save!
          end
          true
        rescue => e
          Raven.capture_exception(e)
          false
        end
      else
        success = message.save
      end

      if success
        join_request.update_column(:last_message_read, message.created_at)
        AsyncService.new(self.class).send_notification(message)
        callback.on_success.try(:call, message)
      else
        callback.on_failure.try(:call, message)
      end
      joinable
    end

    def self.create_broadcast conversation_message_broadcast:, sender:, recipients:, content:
      user = sender
      success_users = []
      failure_users = []

      # refactoriser : code quasi identique dans Admin::ConversationsController.message
      recipients.each do |recipient|
        conversation = self.find_conversation recipient.id, user_id: user.id

        join_request =
          if conversation.new_record?
            conversation.join_requests.to_a.find { |r| r.user_id == user.id }
          else
            user.join_requests.accepted.find_by!(joinable: conversation)
          end

        chat_builder = ChatServices::ChatMessageBuilder.new(
            user: user,
            joinable: conversation,
            join_request: join_request,
            params: {
              message_type: :broadcast,
              conversation_message_broadcast_id: conversation_message_broadcast.id,
              content: content,
            }
        )

        chat_builder.create do |on|
          on.success do |message|
            join_request.update_column(:last_message_read, message.created_at)
            success_users << recipient.id
          end
          on.failure do |message|
            failure_users << recipient.id
          end
        end
      end

      yield success_users, failure_users
    end

    private
    attr_reader :message, :user, :joinable, :join_request, :callback

    def self.send_notification(message)
      group = message.messageable

      group_title =
        if !group.respond_to?(:title) || group.group_type == 'conversation'
          nil
        else
          group.title
        end

      PushNotificationService.new.send_notification(
        UserPresenter.new(user: message.user).display_name,
        group_title,
        message.content,
        recipients(message),
        {
          joinable_id: group.id,
          joinable_type: group.class.name,
          group_type: group.group_type,
          type: "NEW_CHAT_MESSAGE"
        }
      )
    end

    def self.recipients(message)
      message.messageable.members.where("users.id != ? AND status = ?", message.user_id, "accepted")
    end

    def self.find_conversation recipient_id, user_id:
      participants = [recipient_id, user_id]
      uuid_v2 = ConversationService.hash_for_participants(participants)

      Entourage.where(group_type: :conversation).find_by(uuid_v2: uuid_v2) ||
        ConversationService.build_conversation(participant_ids: participants)
    end
  end

  class ChatMessageBuilderCallback < Callback
    attr_accessor :on_freezed_tour

    def freezed_tour(&block)
      @on_freezed_tour = block
    end
  end
end
