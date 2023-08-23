module Api
  module V1
    class EncountersController < Api::V1::BaseController
      before_action :set_tour, only: [:index, :create]
      before_action :set_encounter, only: [:update]

      def index
        encounters = @tour.encounters.page(params[:page]).per(25)
        render json: encounters, status: 201, each_serializer: ::V1::EncounterSerializer
      end

      def create
        reopen_closed_tour_with_warning if @tour.status != 'ongoing'

        encounter = @tour.encounters.new(encounters_params)
        if encounter.save
          EncounterReverseGeocodeJob.perform_later(encounter.id)

          if params[:answers]
            params[:answers].each do |answer_params|
              encounter.answers.create(question_id: answer_params[:question_id], value: answer_params[:value])
            end
          end

          render json: encounter, status: 201, serializer: ::V1::EncounterSerializer
        else
          render json: {message: 'Could not create encouter', reasons: encounter.errors.full_messages}, status: :bad_request
        end
      end

      def update
        if @encounter.update(encounters_params)
          if (@encounter.previous_changes.keys & %w(latitude longitude)).any?
            EncounterReverseGeocodeJob.perform_later(@encounter.id)
          end
          head :no_content
        else
          render json: {message: 'Could not create encouter', reasons: @encounter.errors.full_messages}, status: :bad_request
        end
      end

      private

      def encounters_params
        params.require(:encounter).permit(:street_person_name, :date, :latitude, :longitude, :message, :voice_message, :answers)
      end

      def set_tour
        @tour = Tour.find(params[:tour_id])
      end

      def set_encounter
        @encounter = Encounter.find(params[:id])
      end

      def reopen_closed_tour_with_warning
        return if @tour.ongoing?

        @tour.update!(status: :ongoing)

        begin
          AsyncService.new(TourService).send_reopened_tour_slack_alert(
            tour: @tour,
            api_key: api_request.api_key
          )
        rescue => e
          Raven.capture_exception(e)
        end
      end
    end
  end
end
