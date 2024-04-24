require "securerandom"

module UserServices
  class UserBuilder
    def initialize(params:)
      params ||= {}
      @params = params
      @callback = UserServices::UserBuilderCallback.new
    end

    def token
      SecureRandom.hex(16)
    end

    def create(send_sms: false, sms_code: nil)
      yield callback if block_given?

      return callback.on_invalid_phone_format unless LegacyPhoneValidator.new(phone: params[:phone]).valid?

      sms_code = sms_code || UserServices::SmsCode.new.code
      user = new_user(sms_code)
      UserService.sync_roles(user)

      if user.save
        UserServices::SmsSender.new(user: user).send_welcome_sms(sms_code) if send_sms
        callback.on_success.try(:call, user)
      else
        return callback.on_duplicate(user) if User.where(phone: params[:phone]).count>0
        callback.on_failure.try(:call, user)
      end

      user
    rescue ActiveRecord::RecordNotUnique
      callback.on_duplicate(user)
    end

    def signal_blocked_user user
      return unless user.email.present?
      return unless user.saved_change_to_email?

      blocked_user_ids = User.where(validation_status: :blocked, email: user.email).pluck(:id)

      return if blocked_user_ids.empty?

      SlackServices::SignalUserCreation.new(user: user, blocked_user_ids: blocked_user_ids).notify
    end

    private
    attr_reader :params, :callback

    def new_user
      raise "should be overriden by subclasses"
    end
  end
end
