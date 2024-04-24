module UserServices
  class SmsSender
    def initialize(user:)
      @user = user
    end

    def regenerate_sms!(clear_password: false)
      new_sms = UserServices::SmsCode.new.regenerate_sms!(user: user, clear_password: clear_password)
      send_welcome_sms(new_sms, 'regenerate')
    end

    def send_welcome_sms(sms_code, sms_type='welcome')
      message = "#{sms_code} est votre code de connexion #{user.community.name}. Bienvenue dans le réseau solidaire."
      SmsSenderJob.perform_later(user.phone, message, sms_type)
    end

    private
    attr_reader :user
  end
end
