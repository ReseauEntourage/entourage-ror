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

  def conversation_ids
    (self[:conversation_ids] || []).map(&:to_i)
  end

  def conversation_ids= ids
    self[:conversation_ids] = ids.reject(&:empty?)
  end

  def departements
    Neighborhood.select("left(postal_code, 2) as departement").where(id: conversation_ids).group("left(postal_code, 2)").map(&:departement)
  end

  def departements= departements
    departements = departements.compact.reject(&:empty?)

    return self[:conversation_ids] = [] unless departements.any?

    like_departements = departements.map { |departement| "#{departement}%" }

    self[:conversation_ids] = Neighborhood.where("postal_code LIKE ANY ( array[?] )", like_departements).pluck(:id)
  end

  alias_method :neighborhoods, :recipients
  alias_method :neighborhood_ids, :recipient_ids
  alias_method :neighborhood_ids=, :conversation_ids=

  default_scope { where(conversation_type: messageable_type) }

  def clone
    cloned = super
    cloned.assign_attributes(
      conversation_ids: self[:conversation_ids]
    )
    cloned
  end
end
