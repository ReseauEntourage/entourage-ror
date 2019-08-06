module ModerationServices
  def self.moderator_with_error(community:)
    if community != :entourage
      return nil, :no_moderator_for_community
    end

    scope = User
      .where(community: community)
      .where(admin: true)

    candidates = scope.where(phone: '+33768037348')

    candidates = candidates.to_a

    if candidates.none?
      return nil, :no_candidate
    end

    if candidates.many?
      raise nil, :multiple_candidates
    end

    return candidates.first, nil
  end

  def self.moderator(community:)
    moderator, error = moderator_with_error(community: community)

    return moderator if error.nil?

    case error
    when :no_moderator_for_community
      raise "No moderator is set for #{community}"
    when :no_candidate
      raise "Moderator was not found for #{community}"
    when :multiple_candidates
      raise "Multiple moderator candidates were found for #{community}"
    else
      raise "Error #{error.inspect} for #{community}"
    end
  end

  def self.moderator_if_exists(community:)
    moderator, error = moderator_with_error(community: community)
    return moderator
  end
end
