module UserServices
  class SMSSender
    def initialize(user:)
      @user = user
    end

    def regenerate_sms!
      new_sms = UserServices::UserBuilder.regenerate_sms!(user: user)
      send_welcome_sms(new_sms)
    end

    def send_welcome_sms(sms_code)
      link = Rails.env.test? ? "http://foo.bar" : url_shortener.shorten(Rails.application.routes.url_helpers.store_redirection_url)
      message = "Bienvenue sur Entourage. Votre code est #{sms_code}. Retrouvez l'application ici : #{link} ."
      sms_notification_service.send_notification(user.phone, message)
    end

    private
    attr_reader :user

    def sms_notification_service
      @sms_notification_service ||= SmsNotificationService.new
    end

    def url_shortener
      @url_shortener ||= ShortURL
    end
  end
end