module UserServices
  class UserAuthenticator
    def self.authenticate_by_phone_and_secret(phone:, secret:, platform:)
      return nil if phone.blank? || secret.blank? || platform.blank?

      user = find_user_by_phone phone
      return user if user.nil?

      auth_service = UserServices::AuthenticationService.new(user: user)

      valid_password =
        if platform == :web && user.has_password?
          auth_service.check_password(secret)
        else
          auth_service.check_sms_code(secret) || auth_service.check_password(secret)
        end

      valid_password ? user : nil
    end

    def self.authenticate_by_phone_and_sms(phone:, sms_code:)
      return nil if phone.blank? || sms_code.blank?

      user = find_user_by_phone phone
      return user if user.nil?

      valid_password = UserServices::AuthenticationService.new(user: user).check_sms_code(sms_code)
      valid_password ? user : nil
    end

    private

    def self.find_user_by_phone phone
      user_phone = Phone::PhoneBuilder.new(phone: phone).format
      User.where(phone: user_phone).first
    end
  end
end
