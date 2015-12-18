class RegistrationRequestsController < ApplicationController
  before_filter :authenticate_admin!
  before_filter :set_registration_request, only: [:show, :destroy, :update]

  def index
    @registration_requests = RegistrationRequest.pending.page(params[:page])
  end

  def show
  end

  def destroy
    @registration_request.destroy
    redirect_to registration_requests_path
  end

  def update
    if params["validate"]
      builder = RegistrationRequestServices::RegistrationRequestBuilder.new(registration_request: @registration_request)
      builder.validate!
    end
    redirect_to registration_requests_path
  end

  private
  def set_registration_request
    @registration_request = RegistrationRequest.find(params[:id])
  end
end