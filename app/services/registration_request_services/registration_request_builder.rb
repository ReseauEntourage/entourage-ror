module RegistrationRequestServices
  class RegistrationRequestBuilder
    def initialize(registration_request:)
      @registration_request = registration_request
    end

    def validate!
      organization = Organization.new(registration_request.extra["organization"].except("logo_key"))
      builder = UserServices::UserBuilder.new(params:registration_request.extra["user"], organization:organization)

      ActiveRecord::Base.transaction do
        organization.save!
        builder.create
        registration_request.update(status: "validated")
      end
    end

    private
    attr_reader :registration_request
  end
end