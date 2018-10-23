module UserServices
  class SMSSender
    def initialize(user:)
      @user = user
    end

    def regenerate_sms!(clear_password: false)
      new_sms = UserServices::SmsCode.new.regenerate_sms!(user: user, clear_password: clear_password)
      send_welcome_sms(new_sms)
    end

    def send_welcome_sms(sms_code)
      link = Rails.env.test? ? "http://foo.bar" : user.community.store_short_url.sub(%r{^https?://}, '')
      message = "Bienvenue dans le réseau #{user.community.name}. #{sms_code} est votre code de connexion. Téléchargez l'application ici: #{link} ."
      SmsSenderJob.perform_later(user.phone, message)
    end

    private
    attr_reader :user

    def url_shortener
      @url_shortener ||= ShortURL
    end
  end
end
