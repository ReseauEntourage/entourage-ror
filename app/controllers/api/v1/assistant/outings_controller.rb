module Api
  module V1
    module Assistant
      # Outings close to a place, and the sheet of one outing.
      class OutingsController < BaseController
        MAX_LIMIT = 20

        def search
          outings = ::OutingsServices::Finder.new(assistant_user, finder_params).find_all
          outings = outings.where("COALESCE(entourages.metadata->>'reserved_female', 'false') <> 'true'") unless reserved_female?
          records = outings.includes(:user, :sf_categories).limit(limit).to_a

          counts = participants_counts(records)
          render json: {
            outings: records.map { |outing| ::Assistant::Presenters::EventSheet.new(outing, participants_count: counts[outing.id] || 0).as_json }
          }
        end

        def read
          outing = ::Outing.for_user(assistant_user).find_by_id_or_uuid!(params[:id])

          render json: ::Assistant::Presenters::EventSheet.new(outing, participants_count: participants_counts([outing])[outing.id] || 0).as_json
        end

        private

        # Reserved to women only when the assistant asks for them: an event reserved to women is
        # never returned otherwise.
        def reserved_female?
          params[:reserved_female].to_s == 'true'
        end

        def finder_params
          # `format` is a reserved word of Rails routing: the format of the meeting is `meeting_format`.
          permitted = params.permit(:q, :latitude, :longitude, :within_days, :reserved_female, :category, :meeting_format, :interest_list, interests: [])
          permitted[:travel_distance] = params[:distance] if params[:distance].present?
          permitted[:format] = params[:meeting_format] if params[:meeting_format].present?
          permitted
        end

        def limit
          params[:limit].present? ? params[:limit].to_i.clamp(1, MAX_LIMIT) : 10
        end

        def participants_counts outings
          JoinRequest.accepted.where(joinable_type: 'Entourage', joinable_id: outings.map(&:id)).group(:joinable_id).count
        end
      end
    end
  end
end
