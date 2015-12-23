require "securerandom"

module UserServices
  class UserBuilder
    def initialize(params:, organization: nil)
      @params = params
      @organization = organization
      @callback = Callback.new
    end

    def token
      SecureRandom.hex(16)
    end

    def self.sms_code
      '%06i' % rand(1000000)
    end

    def self.regenerate_sms!(user:)
      new_sms_code = sms_code
      user.sms_code = new_sms_code
      user.save
      new_sms_code
    end

    def new_user
      user = User.new(params)
      user.organization = organization
      user.token = token
      user.sms_code = UserServices::UserBuilder.sms_code
      user
    end

    def create(send_sms: false)
      yield callback if block_given?

      user = new_user
      if user.save
        UserServices::SMSSender.new(user: new_user).send_welcome_sms! if send_sms
        callback.on_create_success.try(:call, user)
      else
        callback.on_create_failure.try(:call, user)
      end
    end

    def update(user:)
      snap_to_road = (params.delete(:snap_to_road) == "true")
      simplified_tour = (params.delete(:simplified_tour) == "true")
      PreferenceServices::UserDefault.new(user: user).snap_to_road = snap_to_road
      PreferenceServices::UserDefault.new(user: user).simplified_tour = simplified_tour
      user.update_attributes(params)
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