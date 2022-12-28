class EntourageDenorm < ApplicationRecord
  belongs_to :entourage

  # create
  def join_request_on_create join_request
    return unless join_request.requested_at
    return unless join_request.message.present?
    return unless join_request.is_accepted? || join_request.is_pending?

    self[:max_join_request_requested_at] = join_request.requested_at
  end

  def chat_message_on_create chat_message
    self[:max_chat_message_created_at] = chat_message.created_at
    self[:has_image_url] ||= chat_message.image_url.present?
  end

  # update
  def join_request_on_update join_request
    recompute_max_join_request_requested_at
  end

  def chat_message_on_update chat_message
  end

  # destroy
  def join_request_on_destroy join_request
    recompute_max_join_request_requested_at
  end

  def chat_message_on_destroy chat_message
  end

  # recompute_and_save
  def recompute_and_save
    recompute_max_join_request_requested_at
    recompute_max_chat_message_created_at
    recompute_has_image_url
  end

  private

  def recompute_max_join_request_requested_at
    self[:max_join_request_requested_at] = JoinRequest.select('max(requested_at) as max_requested_at')
    .where(["joinable_type = 'Entourage' and joinable_id = ?", entourage_id])
    .where("message is not null and message != ''")
    .where(status: [:pending, :accepted])
    .group(:joinable_id)
    .map(&:max_requested_at).max
  end

  def recompute_max_chat_message_created_at
    self[:max_chat_message_created_at] = ChatMessage.select('max(created_at) as max_created_at')
      .where(messageable: entourage)
      .group(:messageable_id)
      .pluck(:max_created_at).max
  end

  def recompute_has_image_url
    self[:has_image_url] = ChatMessage.where(messageable: entourage)
      .where('image_url is not null')
      .any?
  end
end
