class EntourageDenorm < ApplicationRecord
  belongs_to :entourage

  # create
  def chat_message_on_create chat_message
    self[:max_chat_message_created_at] = chat_message.created_at
    self[:has_image_url] ||= chat_message.image_url.present?
  end

  # update
  def chat_message_on_update chat_message
  end

  # destroy
  def chat_message_on_destroy chat_message
    recompute_max_chat_message_created_at
    recompute_has_image_url
  end

  private

  def recompute_max_chat_message_created_at
    self[:max_chat_message_created_at] = ChatMessage.select('max(created_at) as max_created_at')
      .where(messageable: entourage)
      .group(:messageable_id)
      .pluck(:max_chat_message_created_at).max
  end

  def recompute_has_image_url
    self[:has_image_url] = ChatMessage.where(messageable: entourage)
      .where('image_url is not null')
      .any?
  end
end
