module ConversationsHelper
  def display_user_name user
    [user.first_name, user.last_name].map(&:presence).compact.join(' ')
  end

  def conversation_recipients_display_names recipients, max: 3
    count = recipients.count

    recipients = User.where(id: recipients).select(:id, :first_name, :last_name).order(:first_name)

    recipient_names = recipients.first(max).map { |u| [UserPresenter.full_name(u), u.id] }

    if count == (max + 1)
      recipient_names.push ["1 autre personne", nil]
    elsif count > (max + 1)
      recipient_names.push ["#{count - max} autres personnes", nil]
    end

    recipient_names
  end

  def read_for_user? conversation, user
    conversation.join_requests.any? do |join_request|
      join_request.user_id == user.id &&
      join_request.unread_messages_count == 0
    end
  end

  def archived_for_user? conversation, user
    conversation.join_requests.any? do |join_request|
      join_request.user_id == user.id &&
      join_request.archived_at.present? &&
      join_request.archived_at >= (conversation.feed_updated_at || conversation.updated_at)
    end
  end

  def chat_message_with_status(chat_message)
    message_html = if chat_message.deleted?
      content_tag(:p, "Ce message a été supprimé par #{chat_message.deleter&.full_name} le #{l(chat_message.deleted_at, format: :short)} :", style: "color: red;") +
        content_tag(:em, simple_format(chat_message.content(true)).html_safe)
    elsif chat_message.offensible?
      content_tag(:p, "Ce message a été détecté automatiquement comme offensant :", style: "color: red;") +
        content_tag(:em, simple_format(chat_message.content(true)).html_safe)
    elsif chat_message.offensive?
      content_tag(:p, "Ce message a été modéré comme offensant :", style: "color: red;") +
        content_tag(:em, simple_format(chat_message.content(true)).html_safe)
    else
      content_tag(:div, simple_format(chat_message.content).html_safe, id: "chat-message-#{chat_message.id}")
    end

    if chat_message.translation&.foreign?
      translation_html = content_tag(:i, "Traduction: #{object_translation(chat_message, :content, :fr)}")
      message_html += translation_html
    end

    message_html
  end

end
