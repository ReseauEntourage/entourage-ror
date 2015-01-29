class EncountersController < ApplicationController
  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }

  def create
    @encounter = Encounter.new(encounters_params)
    @encounter.user = current_user

    unless @encounter.save
      render 'error', status: :bad_request
    end
  end

  private

  def encounters_params
    if params[:encounter]
      params.require(:encounter).permit(:street_person_name, :date, :latitude, :longitude, :message, :voice_message )
    end
  end

end
