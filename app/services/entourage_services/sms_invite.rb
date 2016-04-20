module EntourageServices
  class SmsInvite
    def initialize(phone_number:, entourage:, inviter:)
      @phone_number = phone_number
      @entourage = entourage
      @callback = SmsInviteCallback.new
      @inviter = inviter
    end

    def send_invite
      yield callback if block_given?

      if EntouragesUser.where(user: inviter, entourage: entourage, status: "accepted").first.nil?
        return callback.on_not_part_of_entourage.try(:call)
      end

      Faire une transaction :
      créer le user puis l'invitation

      invite = EntourageInvitation.new(invitable: entourage,
                                       inviter: inviter,
                                       phone_number: phone_number,
                                       invitation_mode: EntourageInvitation::MODE_SMS)

      if invite.save
        SmsSenderJob.perform_later(phone_number, message)
        callback.on_success.try(:call, invite)
      else
        callback.on_failure.try(:call, invite)
      end
    end

    private
    attr_reader :phone_number, :entourage, :callback, :inviter

    def message
      "Bonjour, vous êtes invité à rejoindre un Entourage. Votre code est #{sms_code}. Retrouvez l'application ici : #{link} ."
    end

    def link
      link = Rails.env.test? ? "http://foo.bar" : url_shortener.shorten(Rails.application.routes.url_helpers.store_redirection_url)
    end
  end

  class SmsInviteCallback < Callback
    attr_accessor :on_not_part_of_entourage

    def not_part_of_entourage(&block)
      @on_not_part_of_entourage = block
    end
  end
end