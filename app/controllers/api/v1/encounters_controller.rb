module Api
  module V1
    class EncountersController < Api::V1::BaseController
      def create
        encounter = Encounter.new(encounters_params)
        if params[:tour_id]
          encounter.tour = Tour.find(params[:tour_id])
        end
        if encounter.save
          EncounterReverseGeocodeJob.perform_later(encounter.id)
          render json: encounter, status: 201
        else
          render json: {message: 'Could not create encouter', reasons: encounter.errors.full_messages}, status: :bad_request
        end
      end

      private

      def encounters_params
        if params[:encounter]
          params.require(:encounter).permit(:street_person_name, :date, :latitude, :longitude, :message, :voice_message )
        end
      end
    end
  end
end
