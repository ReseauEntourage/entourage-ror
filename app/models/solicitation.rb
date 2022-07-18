class Solicitation < Entourage
  default_scope { where(group_type: :action, entourage_type: :ask_for_help).order(feed_updated_at: :desc) }

  def parent_chat_messages
    chat_messages.where(ancestry: nil)
  end
end
