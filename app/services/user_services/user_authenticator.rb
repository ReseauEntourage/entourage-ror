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

    def self.authenticate_with_token(auth_token:, platform:)
      return nil if [auth_token, platform].any?(&:blank?)

      token_data = parse_auth_token auth_token

      return nil if token_data[:valid_signature] != true ||
                    token_data[:expires_at].past?

      token_data[:user]
    end

    def self.authenticate_by_phone_and_sms(phone:, sms_code:)
      return nil if phone.blank? || sms_code.blank?

      user_phone = Phone::PhoneBuilder.new(phone: phone).format
      user = User.where(community: :entourage, phone: user_phone).first
      return user if user.nil?

      valid_password = UserServices::AuthenticationService.new(user: user).check_sms_code(sms_code)
      valid_password ? user : nil
    end

    def self.authenticate_by_phone_and_admin_password(phone:, admin_password:)
      return nil if phone.blank? || admin_password.nil?

      user_phone = Phone::PhoneBuilder.new(phone: phone).format
      user = User.where(community: :entourage, phone: user_phone).first
      return nil if user.nil?

      valid_password = UserServices::AuthenticationService.new(user: user).check_admin_password(admin_password)
      return nil unless valid_password

      user
    end

    def self.auth_token user, expires_in: 7.days
      payload = "#{user.id}-#{expires_in.from_now.to_i}"
      signature = SignatureService.sign(payload, salt: user.token)
      "1_#{payload}-#{signature}"
    end

    def self.parse_auth_token token
      if token.starts_with? '1_'
        user_id, expires_at, signature = token[2..-1].split('-')
        user_id = user_id.to_i
        user = User.find_by(id: user_id)
        valid_signature = signature == SignatureService.sign("#{user_id}-#{expires_at}", salt: user&.token)
        {
          version: 1,
          user_id: user_id,
          expires_at: Time.zone.at(expires_at.to_i),
          valid_signature: valid_signature,
          user: user
        }
      else
        {
          valid_signature: false
        }
      end
    end
  end
end
