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

  def self.moderation_area_query_for_departement departement, community:
    return ModerationArea.none if departement.nil?
    return ModerationArea.none if community != :entourage
    user_id = ModerationArea
      .where(departement: [departement, '*'])
      .order("case departement when '*' then 1 else 0 end")
      .limit(1)
  end

  def self.moderation_area_for_departement departement, community:
    moderation_area_query_for_departement(departement, community: community).first
  end

  def self.moderator_for_departement departement, community:
    user_id = moderation_area_query_for_departement(departement, community: community)
      .pluck(:moderator_id)
      .first
    User.find_by(id: user_id)
  end

  def self.departement_for_object object
    if object.nil? || object.postal_code.nil?
      nil
    elsif object.country == 'FR'
      object.postal_code.first(2)
    else
      '*'
    end
  end

  def self.moderation_area_for_user user
    moderation_area_for_departement(
      departement_for_object(user.address),
      community: user.community,
    )
  end

  def self.moderation_area_for_user_with_default user
    moderation_area_for_user(user) || default_moderation_area
  end

  def self.moderator_for_entourage entourage
    return unless entourage.group_type.in?(['action', 'outing'])
    moderator_for_departement(
      departement_for_object(entourage),
      community: entourage.community
    )
  end

  def self.moderator_for_user user
    moderation_area_for_user_with_default(user)&.moderator
  end

  def self.default_moderation_area
    moderation_area_for_departement('*', community: :entourage)
  end
end
