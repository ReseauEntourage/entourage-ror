module UserSmalltalkable
  extend ActiveSupport::Concern

  included do
    scope :best_matches, -> (user_smalltalk) {
      select_match(user_smalltalk)
        .profile_match(user_smalltalk)
        .merge(matchable_smalltalks)
        .reciprocity_match(user_smalltalk)
        .where.not(user_id: user_smalltalk.user_id)
        .where("user_smalltalks.deleted_at IS NULL")
        .where("user_smalltalks.member_status IS NULL or user_smalltalks.member_status = '#{JoinRequest::ACCEPTED_STATUS}'")
        .order("unmatch_count")
        .order(Arel.sql("CASE WHEN (bool_and(#{user_smalltalk.interest_match_expression})) THEN 1 ELSE 0 END"))
    }

    scope :exact_matches, -> (user_smalltalk) {
      select_match(user_smalltalk)
        .profile_match(user_smalltalk)
        .reciprocity_match(user_smalltalk)
        .merge(matchable_smalltalks)
        .where.not(user_id: user_smalltalk.user_id)
        .where("user_smalltalks.deleted_at IS NULL")
        .where("user_smalltalks.member_status IS NULL or user_smalltalks.member_status = '#{JoinRequest::ACCEPTED_STATUS}'")
        .where(user_smalltalk.format_match_expression)
        .where(user_smalltalk.gender_match_expression)
        .where(user_smalltalk.locality_match_expression)
        .order(Arel.sql("CASE WHEN (bool_and(#{user_smalltalk.interest_match_expression})) THEN 1 ELSE 0 END"))
    }

    scope :select_match, -> (user_smalltalk) {
      select(%(
        min(user_smalltalks.id) as id,
        smalltalk_id,
        min(user_smalltalks.user_id) as user_id,
        array_agg(user_smalltalks.user_id) as user_ids,
        (bool_and(#{user_smalltalk.format_match_expression})) as has_matched_format,
        (bool_and(#{user_smalltalk.gender_match_expression})) as has_matched_gender,
        (bool_and(#{user_smalltalk.locality_match_expression})) as has_matched_locality,
        (bool_and(#{user_smalltalk.interest_match_expression})) as has_matched_interest,
        (bool_and(#{user_smalltalk.profile_match_expression})) as has_matched_profile,
        (
          CASE WHEN (bool_and(#{user_smalltalk.format_match_expression})) THEN 0 ELSE 1 END +
          CASE WHEN (bool_and(#{user_smalltalk.gender_match_expression})) THEN 0 ELSE 1 END +
          CASE WHEN (bool_and(#{user_smalltalk.locality_match_expression})) THEN 0 ELSE 1 END
        ) AS unmatch_count
      ))
    }

    scope :matchable_smalltalks, -> {
      left_outer_joins(:smalltalk).where(
        "user_smalltalks.smalltalk_id IS NULL OR smalltalks.id IN (?)",
        Smalltalk.matchable.select(:id)
      )
    }

    scope :profile_match, -> (user_smalltalk) {
      where.not(user_profile: user_smalltalk.user_profile_before_type_cast)
    }

    scope :reciprocity_match, -> (user_smalltalk) {
      gender_reciprocity(user_smalltalk)
        .locality_reciprocity(user_smalltalk)
        .group(%(
          CASE
            WHEN user_smalltalks.smalltalk_id IS NULL THEN user_smalltalks.id
            ELSE user_smalltalks.smalltalk_id
          END,
          user_smalltalks.smalltalk_id,
          smalltalks.number_of_people
        ))
        .having(%(
          smalltalk_id IS NULL OR smalltalks.number_of_people = count(*)
        ))
    }

    scope :gender_reciprocity, -> (user_smalltalk) {
      return where(match_gender: false) unless user_smalltalk.user_gender_before_type_cast.present?

      where(
        "user_smalltalks.match_gender = false OR user_smalltalks.id IN (?)",
        UserSmalltalk.where(user_gender: user_smalltalk.user_gender_before_type_cast).select(:id)
      )
    }

    scope :locality_reciprocity, -> (user_smalltalk) {
      return where(match_locality: false) unless user_smalltalk.user_longitude.present? && user_smalltalk.user_latitude.present?

      where(%(
        user_smalltalks.match_locality = false OR
        ST_DWithin(
          ST_SetSRID(ST_MakePoint(user_smalltalks.user_longitude, user_smalltalks.user_latitude), 4326)::geography,
          ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography,
          ?
        )),
        user_smalltalk.user_longitude, user_smalltalk.user_latitude, 20_000
      )
    }
  end

  def format_match_expression
    "user_smalltalks.match_format = #{match_format_before_type_cast}"
  end

  def gender_match_expression
    return "1=1" unless match_gender
    return "1=1" unless user_gender_before_type_cast

    "user_smalltalks.user_gender = #{user_gender_before_type_cast}"
  end

  def locality_match_expression
    return "1=1" unless match_locality
    return "1=1" unless user_latitude && user_longitude

    return %(
      ST_DWithin(
        ST_SetSRID(ST_MakePoint(user_smalltalks.user_longitude, user_smalltalks.user_latitude), 4326)::geography,
        ST_SetSRID(ST_MakePoint(#{user_longitude}, #{user_latitude}), 4326)::geography,
        20000
      )
    ) if match_locality && user_latitude && user_longitude

    %(
      user_smalltalks.match_locality = false OR ST_DWithin(
        ST_SetSRID(ST_MakePoint(user_smalltalks.user_longitude, user_smalltalks.user_latitude), 4326)::geography,
        ST_SetSRID(ST_MakePoint(#{user_longitude}, #{user_latitude}), 4326)::geography,
        20000
      )
    )
  end

  def interest_match_expression
    return "1=1" unless user_interest_ids.any?

    "user_smalltalks.user_interest_ids ?| ARRAY[#{
      user_interest_ids.map { |id| "'#{id}'" }.join(', ')
    }]"
  end

  def profile_match_expression
    "user_smalltalks.user_profile != #{user_profile_before_type_cast}"
  end
end
