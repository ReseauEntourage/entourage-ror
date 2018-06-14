module OrganizationServices
  class OrganizationBuiler
    def initialize(params:)
      @params = params
      @callback = Callback.new
    end

    def create
      yield callback if block_given?

      organization = Organization.new(params.except(:user))
      user_params = params[:user].merge({manager: true})
      user_builder = UserServices::ProUserBuilder.new(params: user_params, organization: organization)
      user_builder.create_or_upgrade(send_sms: false) do |on|
        on.success do |user|
          callback.on_success.try(:call, organization, user)
        end

        on.failure do |user|
          callback.on_failure.try(:call, organization, user)
        end
      end
    end

    private
    attr_reader :params, :organization, :callback
  end
end
