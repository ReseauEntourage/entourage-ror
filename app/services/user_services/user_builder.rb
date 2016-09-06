require "securerandom"

module UserServices
  class UserBuilder
    def initialize(params:)
      @params = params
      @callback = UserServices::UserBuilderCallback.new
    end

    def token
      SecureRandom.hex(16)
    end

    def create(send_sms: false, sms_code: nil)
      yield callback if block_given?

      if User.where(phone: params["phone"]).count>0
        return callback.on_duplicate.try(:call)
      end

      sms_code = sms_code || UserServices::SmsCode.new.code
      user = new_user(sms_code)
      if user.save
        UserServices::SMSSender.new(user: user).send_welcome_sms(sms_code) if send_sms
        callback.on_success.try(:call, user)
      else
        callback.on_failure.try(:call, user)
      end
      user
    end

    private
    attr_reader :params, :callback

    def new_user
      raise "should be overriden by subclasses"
    end
  end
end