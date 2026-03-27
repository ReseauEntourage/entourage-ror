class ChatMessagesChannel < ApplicationCable::Channel
  def subscribed
    if params[:messageable_type].present? && params[:messageable_id].present?
      stream_from "chat_messages_#{params[:messageable_type]}_#{params[:messageable_id]}"
    else
      stream_from "chat_messages"
    end
  end

  def unsubscribed
  end
end
