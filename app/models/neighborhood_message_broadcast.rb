class NeighborhoodMessageBroadcast < ConversationMessageBroadcast
  store_accessor :specific_filters, :departements

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
    return neighborhood_ids_in_departements_and_area_type if is_departement_selection?

    (self[:conversation_ids] || []).map(&:to_i)
  end

  def conversation_ids= ids
    self["specific_filters"]["departements"] = nil
    self[:conversation_ids] = ids.map(&:to_s).reject(&:empty?)
  end

  def neighborhood_ids_in_departements_and_area_type
    return [] unless departements.any?

    self.class.neighborhood_ids_in_departements_and_area_type(departements, area_type)
  end

  class << self
    def neighborhood_ids_in_departements_and_area_type departements, area_type
      return [] unless departements.any?

      Neighborhood
        .where("postal_code LIKE ANY ( array[?] )", departements.map { |departement| "#{departement}%" })
        .with_zone(area_type)
        .pluck(:id)
    end
  end

  def is_departement_selection?
    departements.present? && departements.any?
  end

  def departements
    (self["specific_filters"]["departements"] || []).compact.reject(&:empty?)
  end

  alias_method :neighborhoods, :recipients
  alias_method :neighborhood_ids, :recipient_ids
  alias_method :neighborhood_ids=, :conversation_ids=

  default_scope { where(conversation_type: messageable_type) }

  def clone
    cloned = super
    cloned.assign_attributes(
      conversation_ids: self[:conversation_ids],
      specific_filters: self[:specific_filters]
    )
    cloned
  end
end
