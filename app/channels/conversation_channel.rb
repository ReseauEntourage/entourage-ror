class ConversationChannel < ApplicationCable::Channel
  STREAM_PREFIX = "conversation"
  ALLOWED_INSTANCE_TYPES = %w[Entourage Neighborhood].freeze

  def subscribed
    reject and return unless current_user

    instance = find_instance
    reject and return unless instance
    reject and return unless member?(instance)

    stream_from self.class.stream_for(instance)
  end

  def unsubscribed
    stop_all_streams
  end

  class << self
    def broadcast_chat_message_created(message)
      broadcast_event(
        message.messageable,
        type:          "chat_message_created",
        user_id:       message.user_id,
        instance_type: "ChatMessage",
        instance_id:   message.id,
        data:          serialize_chat_message(message)
      )
    end

    def broadcast_chat_message_updated(message)
      broadcast_event(
        message.messageable,
        type:          "chat_message_updated",
        user_id:       message.user_id,
        instance_type: "ChatMessage",
        instance_id:   message.id,
        data:          serialize_chat_message(message)
      )
    end

    def broadcast_user_reaction_added(user_reaction, chat_message)
      broadcast_reaction_event(user_reaction, chat_message, "user_reaction_added")
    end

    def broadcast_user_reaction_removed(user_reaction, chat_message)
      broadcast_reaction_event(user_reaction, chat_message, "user_reaction_removed")
    end

    def stream_for(instance)
      "#{STREAM_PREFIX}:#{instance.class.name}:#{instance.id}"
    end

    private

    def broadcast_event(messageable, type:, user_id:, instance_type:, instance_id:, data:)
      return unless messageable

      ActionCable.server.broadcast(
        stream_for(messageable),
        {
          type:          type,
          user_id:       user_id,
          instance_type: instance_type,
          instance_id:   instance_id,
          data:          data
        }
      )
    end

    def broadcast_reaction_event(user_reaction, chat_message, type)
      broadcast_event(
        chat_message.messageable,
        type:          type,
        user_id:       user_reaction.user_id,
        instance_type: "UserReaction",
        instance_id:   user_reaction.id,
        data: {
          id:              user_reaction.id,
          reaction_id:     user_reaction.reaction_id,
          user_id:         user_reaction.user_id,
          chat_message_id: chat_message.id
        }
      )
    end

    def serialize_chat_message(message)
      V1::ChatMessageSerializer.new(message, scope: {}, root: false).as_json
    end
  end

  private

  def find_instance
    type = params[:instance_type].to_s
    id   = params[:instance_id]
    return nil unless ALLOWED_INSTANCE_TYPES.include?(type)

    type.constantize.find_by(id: id)
  end

  def member?(instance)
    instance.join_requests.where(status: :accepted, user: current_user).exists?
  end
end
