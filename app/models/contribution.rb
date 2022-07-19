class Contribution < Entourage
  include Actionable

  default_scope { where(group_type: :action, entourage_type: :contribution).order(feed_updated_at: :desc) }

  def parent_chat_messages
    chat_messages.where(ancestry: nil)
  end
end
