require "securerandom"

module UserServices
  class UserBuilder
    def initialize(params:)
      @params = params
      @callback = UserServices::Callback.new
    end

    def token
      SecureRandom.hex(16)
    end

    def create(send_sms: false, sms_code: nil)
      yield callback if block_given?

      sms_code = sms_code || UserServices::SmsCode.new.code
      user = new_user(sms_code)
      if user.save
        UserServices::SMSSender.new(user: user).send_welcome_sms(sms_code) if send_sms
        callback.on_create_success.try(:call, user)
      else
        callback.on_create_failure.try(:call, user)
      end
      user
    end

    private
    attr_reader :params, :callback
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