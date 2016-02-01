module OrganizationServices
  class OrganizationBuiler
    def initialize(params:)
      @params = params
      @callback = OrganizationServices::Callback.new
    end

    def create
      yield callback if block_given?

      organization = Organization.new(params.except(:user))
      user_params = params[:user].merge({manager: true})
      user_builder = UserServices::ProUserBuilder.new(params: user_params, organization: organization)
      user_builder.create(send_sms: false) do |on|
        on.create_success do |user|
          callback.on_create_success.try(:call, organization, user)
        end

        on.create_failure do |user|
          callback.on_create_failure.try(:call, organization, user)
        end
      end
    end

    private
    attr_reader :params, :organization, :callback
  end

  class Callback
    attr_accessor :on_create_success, :on_create_failure

    def create_success(&block)
      @on_create_success = block
    end

    def create_failure(&block)
      @on_create_failure = block
    end
  end
end
