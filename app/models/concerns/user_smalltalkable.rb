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
        .order("unmatch_count")
        .order(Arel.sql("CASE WHEN (#{user_smalltalk.interest_match_expression}) THEN 1 ELSE 0 END"))
    }

    scope :select_match, -> (user_smalltalk) {
      select(%(
        user_smalltalks.*,
        (#{user_smalltalk.format_match_expression}) as has_matched_format,
        (#{user_smalltalk.gender_match_expression}) as has_matched_gender,
        (#{user_smalltalk.locality_match_expression}) as has_matched_locality,
        (#{user_smalltalk.interest_match_expression}) as has_matched_interest,
        (#{user_smalltalk.profile_match_expression}) as has_matched_profile,
        (
          CASE WHEN (#{user_smalltalk.format_match_expression}) THEN 0 ELSE 1 END +
          CASE WHEN (#{user_smalltalk.gender_match_expression}) THEN 0 ELSE 1 END +
          CASE WHEN (#{user_smalltalk.locality_match_expression}) THEN 0 ELSE 1 END
        ) AS unmatch_count
      ))
    }

    scope :exact_matches, -> (user_smalltalk) {
      profile_match(user_smalltalk)
        .reciprocity_match(user_smalltalk)
        .merge(matchable_smalltalks)
        .where.not(user_id: user_smalltalk.user_id)
        .where("user_smalltalks.deleted_at IS NULL")
        .where(user_smalltalk.format_match_expression)
        .where(user_smalltalk.gender_match_expression)
        .where(user_smalltalk.locality_match_expression)
        .order(Arel.sql("CASE WHEN (#{user_smalltalk.interest_match_expression}) THEN 1 ELSE 0 END"))
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
