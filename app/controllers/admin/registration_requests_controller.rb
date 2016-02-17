module Admin
  class RegistrationRequestsController < Admin::BaseController
    before_filter :authenticate_admin!
    before_filter :set_registration_request, only: [:show, :destroy, :update]

    def index
      @registration_requests = if params[:status] == "validated"
                                 RegistrationRequest.validated
                               elsif params[:status] == "rejected"
                                 RegistrationRequest.rejected
                               else
                                 RegistrationRequest.pending
                               end
      @registration_requests = @registration_requests.page(params[:page])
    end

    def show
      logo = @registration_request.organization_field("logo_key")
      @image_url = logo.blank? ? "" : Storage::Client.images.url_for(key: logo)
    end

    def destroy
      @registration_request.update(status: "rejected")
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
end