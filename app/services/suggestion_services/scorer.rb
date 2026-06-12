# frozen_string_literal: true

module SuggestionServices
  # Scores a candidate joinable (Entourage outing or Neighborhood) for a given user,
  # based on the user's lifecycle segment and a set of weighted scoring components.
  class Scorer # rubocop:disable Metrics/ClassLength
    LIFECYCLE_WEIGHTS = {
      new:         { distance: 0.50, interest: 0.40, popularity: 0.10 },
      active:      { distance: 0.30, history: 0.25, interest: 0.20, social_proof: 0.15, segment: 0.10 },
      churn_risk:  { distance: 0.30, history: 0.30, interest: 0.20, social_proof: 0.10, segment: 0.10 },
      churning:    { distance: 0.25, history: 0.35, interest: 0.15, social_proof: 0.15, segment: 0.10 },
      hibernating: { distance: 0.25, history: 0.30, interest: 0.15, social_proof: 0.10, segment: 0.20 }
    }.freeze

    attr_reader :lifecycle_segment

    def initialize(user)
      @user              = user
      @user_lat          = user.address&.latitude
      @user_lng          = user.address&.longitude
      @user_tags         = user.interest_list.to_a
      @joined_ids        = joined_joinable_ids
      @lifecycle_segment = compute_lifecycle_segment
    end

    def score(candidate) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      weights    = LIFECYCLE_WEIGHTS[@lifecycle_segment]
      components = {}

      components[:distance]     = distance_score(candidate)
      components[:history]      = history_score(candidate)      if weights[:history]
      components[:interest]     = interest_score(candidate)
      components[:social_proof] = social_proof_score(candidate) if weights[:social_proof]
      components[:segment]      = segment_boost(candidate)      if weights[:segment]

      total   = components.sum { |key, val| val * (weights[key] || 0) }
      reasons = build_reasons(components, weights, candidate)

      [total.round(4), reasons]
    end

    private

    def compute_lifecycle_segment # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength
      badge = EngagementLevel.find_by(user_id: @user.id)&.badge
      case badge
      when 'SUPER_ENGAGE', 'ENGAGE'
        :active
      when 'OBSERVE'
        @user.last_sign_in_at&.> 30.days.ago ? :active : :churn_risk
      when 'PASSIVE'
        :churning
      when 'SILENT'
        :hibernating
      else
        @user.created_at > 14.days.ago ? :new : :churning
      end
    end

    def distance_score(candidate) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength
      return 0.0 unless @user_lat && @user_lng
      return 0.0 unless candidate.respond_to?(:latitude) && candidate.latitude

      dist_km = Geocoder::Calculations.distance_between(
        [@user_lat, @user_lng],
        [candidate.latitude, candidate.longitude],
        units: :km
      )
      max_km = (@user.travel_distance || 40).to_f
      return 1.0 if dist_km <= 0.5
      return 0.1 if dist_km >= max_km

      1.0 - ((dist_km - 0.5) / (max_km - 0.5)) * 0.9
    end

    def history_score(candidate)
      return 0.0 if @joined_ids.empty?

      candidate_tags = candidate.interest_list.to_a
      return 0.0 if candidate_tags.empty?

      past_tags = past_participation_tags
      return 0.0 if past_tags.empty?

      common = (candidate_tags & past_tags).size
      (common.to_f / candidate_tags.size).clamp(0.0, 1.0)
    end

    def interest_score(candidate)
      return 0.0 if @user_tags.empty?

      candidate_tags = candidate.interest_list.to_a
      return 0.0 if candidate_tags.empty?

      common = (@user_tags & candidate_tags).size
      (common.to_f / [@user_tags.size, candidate_tags.size].min).clamp(0.0, 1.0)
    end

    def social_proof_score(candidate) # rubocop:disable Metrics/MethodLength
      joinable_type = candidate.class.name
      member_ids = JoinRequest
        .where(joinable_type: joinable_type, joinable_id: candidate.id, status: 'accepted')
        .pluck(:user_id)
      return 0.0 if member_ids.empty?

      user_network_ids = JoinRequest
        .where(user_id: @user.id, status: 'accepted')
        .joins("JOIN join_requests jr2 ON jr2.joinable_id = join_requests.joinable_id
                AND jr2.joinable_type = join_requests.joinable_type")
        .distinct
        .pluck('jr2.user_id')

      common = (member_ids & user_network_ids).size
      [common.to_f / 5.0, 1.0].min
    end

    def segment_boost(candidate)
      case @lifecycle_segment
      when :hibernating, :churning
        history_score(candidate)
      when :new
        candidate.respond_to?(:title) && candidate.title&.downcase&.include?('papotage') ? 1.0 : 0.3
      else
        0.5
      end
    end

    def build_reasons(components, weights, candidate)
      components
        .select { |k, v| (v * (weights[k] || 0)) > 0.05 }
        .sort_by { |k, v| -(v * (weights[k] || 0)) }
        .first(3)
        .filter_map { |key, _| reason_text(key, candidate) }
    end

    def reason_text(factor, candidate) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength
      case factor
      when :distance
        return nil unless @user_lat

        dist_km = Geocoder::Calculations.distance_between(
          [@user_lat, @user_lng],
          [candidate.latitude, candidate.longitude],
          units: :km
        ).round(1)
        { icon: 'location', text: "À #{dist_km} km de chez vous" }
      when :history
        { icon: 'history', text: 'Vous avez participé à des activités similaires' }
      when :interest
        common = (@user_tags & candidate.interest_list.to_a).first
        common ? { icon: 'interest', text: "Correspond à votre intérêt : #{common}" } : nil
      when :social_proof
        { icon: 'group', text: 'Des membres de votre réseau y participent' }
      when :segment
        segment_reason_text
      end
    end

    def segment_reason_text
      case @lifecycle_segment
      when :churning, :hibernating
        { icon: 'time', text: "Cela faisait un moment — on a pensé à vous" }
      when :new
        { icon: 'time', text: 'Un bon premier pas pour se lancer' }
      end
    end

    def past_participation_tags # rubocop:disable Metrics/MethodLength
      past_joinable_ids = JoinRequest
        .where(user_id: @user.id, status: 'accepted')
        .pluck(:joinable_type, :joinable_id)

      tags = []
      past_joinable_ids.each do |type, id|
        klass = type.constantize
        obj   = klass.find_by(id: id)
        tags += obj.interest_list.to_a if obj&.respond_to?(:interest_list)
      rescue NameError
        next
      end
      tags.uniq
    end

    def joined_joinable_ids
      JoinRequest.where(user_id: @user.id, status: 'accepted').pluck(:joinable_id)
    end
  end
end
