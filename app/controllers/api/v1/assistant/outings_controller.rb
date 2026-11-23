module Api
  module V1
    module Assistant
      # Outings close to a place, and the sheet of one outing.
      class OutingsController < BaseController
        DEFAULT_LIMIT = 10
        # The assistant filters on the size itself (`size`): it needs more outings to choose from.
        SIZE_LIMIT = 30

        def search
          coordinates = coordinates_for_city(params[:city])
          return if coordinates.nil?

          outings = ::OutingsServices::Finder.new(assistant_user, finder_params.merge(coordinates)).find_all
          outings = outings.where("COALESCE(entourages.metadata->>'reserved_female', 'false') <> 'true'") unless reserved_female?
          # A solidarity chat is the last resort, never mixed with the outings in person: only when asked for.
          outings = outings.where.not(id: ::Outing.unscoped.papotages.select(:id)) unless chatting?
          outings = outings.where(ISO_DAY_SQL, days) if days.any?
          records = outings.includes(:user, :sf_categories).limit(params[:size].present? ? SIZE_LIMIT : DEFAULT_LIMIT).to_a

          counts = ::Assistant::Presenters::EventBrief.counts(records)
          render json: {
            outings: records.map { |outing| ::Assistant::Presenters::EventBrief.new(outing, participants_count: counts[outing.id] || 0).as_json }
          }
        end

        def read
          outing = ::Outing.for_user(assistant_user).find_by_id_or_uuid!(params[:id])
          count = ::Assistant::Presenters::EventBrief.counts([outing])[outing.id] || 0

          render json: ::Assistant::Presenters::EventSheet.new(outing, participants_count: count).as_json
        end

        private

        # Day of the week (1 = Monday) of the start of the outing, in the time zone of the app.
        ISO_DAY_SQL = "EXTRACT(ISODOW FROM ((entourages.metadata->>'starts_at')::timestamptz AT TIME ZONE 'Europe/Paris')) IN (?)".freeze

        def chatting?
          params[:chatting].to_s == 'true'
        end

        # Reserved to women only when the assistant asks for them: an event reserved to women is
        # never returned otherwise.
        def reserved_female?
          params[:reserved_female].to_s == 'true'
        end

        # `days`: ISO numbers 1..7 separated by commas, anything else is ignored.
        def days
          @days ||= params[:days].to_s.split(',').map(&:strip).select { |day| day.match?(/\A[1-7]\z/) }.map(&:to_i).uniq
        end

        def finder_params
          permitted = ActionController::Parameters.new(
            interest_list: params[:interest].to_s.presence,
            category: ('papotages' if chatting?),
            reserved_female: params[:reserved_female].to_s
          ).permit!
          permitted
        end
      end
    end
  end
end
