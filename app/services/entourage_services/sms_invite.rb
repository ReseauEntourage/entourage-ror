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

      begin
        invite = EntourageInvitation.new(invitable: entourage,
                                         inviter: inviter,
                                         phone_number: phone_number,
                                         invitation_mode: EntourageInvitation::MODE_SMS)
        ActiveRecord::Base.transaction do
          invite.save!

          SmsSenderJob.perform_later(phone_number, message)
          callback.on_success.try(:call, invite)
        end
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n")
        callback.on_failure.try(:call, invite)
      end
    end

    private
    attr_reader :phone_number, :entourage, :callback, :inviter

    def invitee
      return @invitee  if @invitee
      @invitee = UserServices::PublicUserBuilder.new(params: {phone: phone_number}).create(send_sms: false)
      raise ActiveRecord::RecordInvalid.new(@invitee) unless @invitee.valid?
      @invitee
    end

    def message
      "Bonjour, vous êtes invité à rejoindre un Entourage. Votre code est #{invitee.sms_code}. Retrouvez l'application ici : #{link} ."
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