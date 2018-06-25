module UserServices
  class UserAuthenticator
    def self.authenticate(community:, phone:, secret:, platform:)
      return nil if [community, phone, secret, platform].any?(&:blank?)

      user_phone = Phone::PhoneBuilder.new(phone: phone).format
      user = community.users.where(phone: user_phone).first
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

      user_phone = Phone::PhoneBuilder.new(phone: phone).format
      user = User.where(community: :entourage, phone: user_phone).first
      return user if user.nil?

      valid_password = UserServices::AuthenticationService.new(user: user).check_sms_code(sms_code)
      valid_password ? user : nil
    end
  end
end
