class Outing < Entourage
  validate :validate_neighborhood_ids

  default_scope { where(group_type: :outing) }

  def validate_neighborhood_ids
    return unless outing?
    return if neighborhood_ids.empty?

    if (neighborhood_ids - user.neighborhood_participation_ids).any?
      errors.add(:neighborhood_ids, "User has to be a member of every neighborhoods")
    end
  end
end
