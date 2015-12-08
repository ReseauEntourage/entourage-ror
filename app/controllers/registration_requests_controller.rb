class RegistrationRequestsController < InheritedResources::Base

  skip_before_filter :require_login

  def index
    @registration_requests = RegistrationRequest.all.page(params[:page])
  end

  def create
    validator = RegistrationRequestValidator.new(params: registration_request_params)
    unless validator.valid?
      return render json: {errors: ["Missing required organization and user infos"]}, status: 400
    end

    registration_request = RegistrationRequest.new(status: "pending",
                                                   extra: registration_request_params.to_json)
    registration_request.save!
    render json: {registration_request: registration_request.as_json}, status: 201
  end

  private

    def registration_request_params
      params.require(:registration_request).permit({organization: [:name, :description, :phone, :address]}, {user: [:first_name, :last_name, :email, :phone]})
    end
end

