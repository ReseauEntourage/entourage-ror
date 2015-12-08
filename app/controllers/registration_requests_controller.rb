class RegistrationRequestsController < GuiController
  skip_before_filter :require_login, only: [:create]
  before_filter :set_registration_request, only: [:show, :destroy, :update]

  def index
    @registration_requests = RegistrationRequest.pending.page(params[:page])
  end

  def create
    validator = RegistrationRequestValidator.new(params: registration_request_params)
    unless validator.valid?
      return render json: {errors: {organization: validator.organization_errors, user: validator.user_errors}}, status: 400
    end

    registration_request = RegistrationRequest.new(status: "pending",
                                                   extra: registration_request_params)
    registration_request.save!
    render json: {registration_request: registration_request.as_json}, status: 201
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

  def registration_request_params
    params.require(:registration_request).permit({organization: [:name, :description, :phone, :address]}, {user: [:first_name, :last_name, :email, :phone]})
  end

  def set_registration_request
    @registration_request = RegistrationRequest.find(params[:id])
  end
end

