class UserDenorm < ActiveRecord::Base
  # observes :join_request, :chat_message, :entourage
  belongs_to :user
  belongs_to :entourage, primary_key: :last_created_action_id
  belongs_to :join_request, primary_key: :last_join_request_id
  belongs_to :chat_message, primary_key: :last_private_chat_message_id
  belongs_to :chat_message, primary_key: :last_group_chat_message_id

  # create
  def join_request_on_create join_request
  end

  def chat_message_on_create chat_message
    return unless chat_message.entourage.group_type in ['action', 'outing']
  end

  def entourage_on_create entourage
    return unless entourage.group_type in ['action', 'outing']
  end

  # update
  def join_request_on_update join_request
  end

  def chat_message_on_update chat_message
    return unless chat_message.entourage.group_type in ['action', 'outing']
  end

  def entourage_on_update entourage
    return unless entourage.group_type in ['action', 'outing']
  end

  # destroy
  def join_request_on_destroy join_request
  end

  def chat_message_on_destroy chat_message
  end

  def entourage_on_destroy entourage
  end

  def recompute_and_save
    recompute_last_created_action_id
    recompute_last_join_request_id
    recompute_last_private_chat_message_id
    recompute_last_group_chat_message_id
    save
  end

  private

  def recompute_last_created_action_id
  end

  def recompute_last_join_request_id
  end

  def recompute_last_private_chat_message_id
  end

  def recompute_last_group_chat_message_id
  end

end
