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
    self[:conversation_ids] = ids.map(&:to_s).reject(&:empty?)
  end

  def departements
    @departements ||= Neighborhood
      .select('left(postal_code, 2) as departement')
      .where(id: conversation_ids)
      .group('left(postal_code, 2)')
      .map(&:departement)
  end

  def departements= departements
    self[:conversation_ids] = self.class.neighborhood_ids_in_departements(departements)
  end

  def self.neighborhood_ids_in_departements departements
    departements = departements.compact.reject(&:empty?)

    return [] unless departements.any?

    like_departements = departements.map { |departement| "#{departement}%" }

    Neighborhood.where('postal_code LIKE ANY ( array[?] )', like_departements).pluck(:id)
  end

  # indicates whether the broadcast concerns all the neighborhoods of the concerned departements
  def has_full_departements_selection?
    self.class.neighborhood_ids_in_departements(departements).compact.uniq.sort == conversation_ids.compact.uniq.sort
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
