# frozen_string_literal: true

module Api
  module V1
    # Returns personalised suggestions (outings and neighborhoods) for the current user,
    # ranked by a lifecycle-aware scoring engine.
    class SuggestionsController < Api::V1::BaseController
      def index # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
        scorer     = SuggestionServices::Scorer.new(current_user)
        finder     = SuggestionServices::Finder.new(current_user)
        candidates = finder.candidates

        scored = candidates.filter_map do |candidate|
          score, reasons = scorer.score(candidate)
          next if score <= 0

          type = candidate.kind_of?(Neighborhood) ? 'neighborhood' : 'outing'
          dist = distance_km(candidate)

          { candidate: candidate, type: type, score: score, reasons: reasons, distance: dist }
        end

        ranked    = scored.sort_by { |s| -s[:score] }
        per_page  = per(params[:per])
        paginated = Kaminari.paginate_array(ranked)
                            .page(params[:page])
                            .per(per_page)

        render json: {
          lifecycle_segment: scorer.lifecycle_segment,
          suggestions:       paginated.map { |s| V1::SuggestionSerializer.new(s).as_json },
          meta:              {
            current_page: paginated.current_page,
            total_pages:  paginated.total_pages,
            total_count:  paginated.total_count
          }
        }
      end

      private

      def per(value)
        [[value.to_i, 1].max, 50].min.clamp(1, 50)
      rescue StandardError
        10
      end

      def distance_km(candidate)
        lat = current_user.address&.latitude
        lng = current_user.address&.longitude
        return nil unless lat && lng && candidate.respond_to?(:latitude) && candidate.latitude

        Geocoder::Calculations.distance_between(
          [lat, lng],
          [candidate.latitude, candidate.longitude],
          units: :km
        ).round(1)
      end
    end
  end
end
