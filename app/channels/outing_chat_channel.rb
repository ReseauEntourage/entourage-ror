class OutingChatChannel < ApplicationCable::Channel
  STREAM_PREFIX = "outing_chat"

  def subscribed
    reject and return unless current_user

    outing = Entourage.find_by(id: params[:outing_id], group_type: :outing)
    reject and return unless outing

    # Seuls les membres acceptés peuvent s'abonner
    reject and return unless outing.join_requests.where(status: :accepted, user: current_user).exists?

    stream_from self.class.stream_for(params[:outing_id])
  end

  def unsubscribed
    stop_all_streams
  end

  def self.broadcast_new_message(message)
    ActionCable.server.broadcast(
      stream_for(message.messageable_id),
      {
        type:       "new_message",
        outing_id:  message.messageable_id,
        user_id:    message.user_id,
        message_id: message.id,
        created_at: message.created_at.iso8601
      }
    )
  end

  def self.stream_for(outing_id)
    "#{STREAM_PREFIX}:#{outing_id}"
  end
end
