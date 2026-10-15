module MatchingServices
  # Hybrid score of a candidate: closeness of meaning first, then distance, freshness and category.
  # Every signal is between 0 and 1; a signal that does not apply (a resource has no distance) is neutral.
  module Scorer
    WEIGHTS = { similarity: 0.6, proximity: 0.2, freshness: 0.1, category: 0.1 }.freeze
    NEUTRAL = 0.5

    # cosine similarities of text-embedding-3-small between two French texts: about 0.3 when unrelated, 0.6 when close
    SIMILARITY_FLOOR = 0.2
    SIMILARITY_CEILING = 0.7

    # the shortlist keeps the best candidates of each type, so that one type cannot fill it alone
    PER_TYPE = 3
    SHORTLIST_SIZE = 10

    def self.score candidate, max_distance_km
      signals = {
        similarity: ((candidate.similarity - SIMILARITY_FLOOR) / (SIMILARITY_CEILING - SIMILARITY_FLOOR)).clamp(0, 1),
        proximity: proximity(candidate.distance_km, max_distance_km),
        freshness: candidate.freshness || NEUTRAL,
        category: candidate.category_match ? 1 : 0
      }

      WEIGHTS.sum { |signal, weight| weight * signals[signal] }
    end

    def self.proximity distance_km, max_distance_km
      return NEUTRAL unless distance_km && max_distance_km.to_f.positive?

      1 - (distance_km / max_distance_km.to_f).clamp(0, 1)
    end

    # @return the best candidates, best first
    def self.shortlist candidates
      candidates
        .group_by(&:type)
        .values
        .flat_map { |candidates_of_type| candidates_of_type.max_by(PER_TYPE, &:score) }
        .max_by(SHORTLIST_SIZE, &:score)
    end
  end
end
