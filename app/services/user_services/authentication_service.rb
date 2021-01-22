module UserServices
  class AuthenticationService
    def initialize(user:)
      @user = user
    end

    def check_sms_code(submitted_sms_code)
      check_secret submitted_sms_code, attribute: :sms_code
    end

    def check_password(submitted_password)
      check_secret submitted_password, attribute: :encrypted_password
    end

    def check_admin_password(submitted_password)
      check_secret submitted_password, attribute: :encrypted_admin_password
    end

    private
    attr_reader :user

    def check_secret submitted_secret, attribute:
      raise AttributeError unless attribute.in?([:sms_code, :encrypted_password, :encrypted_admin_password])

      user_secret_hash = user.send attribute
      return false if user_secret_hash.nil?

      begin
        user_secret = BCrypt::Password.new(user_secret_hash)
      rescue BCrypt::Errors::InvalidHash => e
        Rails.logger.error e
        return false
      end

      user_secret == submitted_secret
    end
  end
end
