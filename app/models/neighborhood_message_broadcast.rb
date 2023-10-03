class NeighborhoodMessageBroadcast < ConversationMessageBroadcast
  class << self
    def messageable_type
      'Neighborhood'
    end
  end

  def recipients
    Neighborhood.where(id: recipient_ids)
  end

  def recipient_ids
    conversation_ids
  end

  def clone
    cloned = super
    cloned.assign_attributes(
      conversation_ids: conversation_ids
    )
    cloned
  end
end
