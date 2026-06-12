# frozen_string_literal: true

module SuggestionServices
  # Finds candidate joinables (outings and neighborhoods) near the user.
  class Finder
    MAX_OUTINGS       = 20
    MAX_NEIGHBORHOODS = 10

    def initialize(user)
      @user   = user
      @lat    = user.address&.latitude
      @lng    = user.address&.longitude
      @radius = user.travel_distance.presence || 40
    end

    def candidates
      outings + neighborhoods
    end

    private

    def outings # rubocop:disable Metrics/MethodLength
      return [] unless @lat && @lng

      Entourage
        .where(group_type: 'outing', status: 'open')
        .where("(metadata->>'starts_at')::timestamp > ?", Time.current)
        .where("(metadata->>'starts_at')::timestamp < ?", 30.days.from_now)
        .inside_perimeter(@lat, @lng, @radius)
        .where.not(id: already_joined_ids('Entourage'))
        .order(Arel.sql("ST_Distance(
          ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography,
          ST_SetSRID(ST_MakePoint(#{@lng.to_f}, #{@lat.to_f}), 4326)::geography
        )"))
        .limit(MAX_OUTINGS)
    end

    def neighborhoods
      return [] unless @lat && @lng

      Neighborhood
        .where(status: 'active')
        .inside_perimeter(@lat, @lng, @radius)
        .where.not(id: already_joined_ids('Neighborhood'))
        .order(Arel.sql("ST_Distance(
          ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography,
          ST_SetSRID(ST_MakePoint(#{@lng.to_f}, #{@lat.to_f}), 4326)::geography
        )"))
        .limit(MAX_NEIGHBORHOODS)
    end

    def already_joined_ids(joinable_type)
      JoinRequest
        .where(user_id: @user.id, joinable_type: joinable_type, status: 'accepted')
        .pluck(:joinable_id)
    end
  end
end
