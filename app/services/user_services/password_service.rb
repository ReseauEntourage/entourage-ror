module UserServices
  class PasswordService
    def initialize(user:)
      @user = user
    end

    def check_password(another_password)
      begin
        sms_code = BCrypt::Password.new(@user.sms_code)
      rescue BCrypt::Errors::InvalidHash => e
        Rails.logger.error e
        return false
      end
      sms_code == another_password
    end

    private
    attr_reader :user
  end
end