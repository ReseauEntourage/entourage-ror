module NextSteps
  # Ranks the candidates of one type: 0.50 × distance + 0.40 × interests +
  # 0.10 × popularity (design.md, decision 5). A component that makes no sense
  # for the type, or is not available, is dropped and its weight spread over the
  # others in proportion.
  #
  # - distance: 1 at the user's place, 0 at their travel distance or beyond
  # - interests: share of the user's interests the candidate shares
  # - popularity: log(1 + n) / log(1 + n_max) among the candidates
  class Score
    WEIGHTS = { distance: 0.50, interests: 0.40, popularity: 0.10 }.freeze

    def initialize user
      @user = user
      @user_interests = user.interest_list.to_a
      @travel_distance = UserService.travel_distance(user: user).to_f
    end

    # @return [Array<Candidate>] the candidates, scored, best first (ties keep their order)
    def rank candidates
      max_popularity = candidates.map(&:popularity).compact.max

      candidates.each { |candidate| score!(candidate, max_popularity) }
      candidates.each_with_index.sort_by { |candidate, index| [-candidate.score, index] }.map(&:first)
    end

    private

    attr_reader :user, :user_interests, :travel_distance

    def score! candidate, max_popularity
      components = {}

      if located?(candidate)
        candidate.distance_km = Geocoder::Calculations.distance_between(
          [user.latitude, user.longitude], [candidate.latitude, candidate.longitude], units: :km
        )
        components[:distance] = 1 - [candidate.distance_km / travel_distance, 1].min if travel_distance.positive?
      end

      if user_interests.any? && !candidate.interest_list.nil?
        components[:interests] = (candidate.interest_list & user_interests).size.to_f / user_interests.size
      end

      if candidate.popularity && max_popularity.to_i.positive?
        components[:popularity] = Math.log(1 + candidate.popularity) / Math.log(1 + max_popularity)
      end

      total_weight = components.keys.sum { |component| WEIGHTS[component] }

      candidate.score_components = components
      candidate.score = total_weight.zero? ? 0.0 : components.sum { |component, value| WEIGHTS[component] * value } / total_weight
    end

    def located? candidate
      user.latitude.present? && user.longitude.present? && candidate.latitude.present? && candidate.longitude.present?
    end
  end
end
