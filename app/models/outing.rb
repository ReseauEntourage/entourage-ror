class Outing < Entourage
  include Interestable

  validate :validate_neighborhood_ids

  default_scope { where(group_type: :outing) }

  def validate_neighborhood_ids
    return unless outing?
    return if neighborhood_ids.empty?

    if (neighborhood_ids - user.neighborhood_participation_ids).any?
      errors.add(:neighborhood_ids, "User has to be a member of every neighborhoods")
    end
  end

  def interests= interests
    unless interests.compact.map(&:to_sym).include?(:other)
      self[:other_interest] = nil
    end

    super(interests)
  end
end
