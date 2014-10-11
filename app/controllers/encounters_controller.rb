class EncountersController < ApplicationController
  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }

  def index
    @encounters = Encounter.all
  end

  def create
    @encounter = Encounter.create(encounters_params)

    if @encounter.valid?
      redirect_to action: 'index'
    else
      render :json => { :errors => @encounter.errors.full_messages }, :status => 403
    end
  end

  private

  def encounters_params
    params.require(:encounter).permit(:location, :user_id, :street_person_name, :message)
  end

end
