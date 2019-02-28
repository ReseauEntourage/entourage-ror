module RegistrationRequestServices
  class RegistrationRequestBuilder
    def initialize(registration_request:)
      @registration_request = registration_request
    end

    def validate!
      organization = Organization.new(registration_request.extra["organization"].except("logo_key"))
      builder = UserServices::ProUserBuilder.new(params:registration_request.extra["user"], organization:organization)

      ActiveRecord::Base.transaction do
        organization.save!
        builder.create_or_upgrade(send_sms: true) do |on|
          on.success do |user|
            user.update(manager: true)
            registration_request.update(status: "validated")
            MemberMailer.registration_request_accepted(user).try(:deliver_later)
          end

          on.failure do |user|
            raise ActiveRecord::Rollback
          end
        end
      end
    end

    private
    attr_reader :registration_request
  end
end
