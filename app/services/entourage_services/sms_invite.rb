module EntourageServices
  class SmsInvite
    def initialize(phone_number:, entourage:, inviter:)
      @phone_number = phone_number
      @entourage = entourage
      @callback = Callback.new
      @inviter = inviter
    end

    def send_invite
      yield callback if block_given?
      invite = EntourageInvitation.new(invitable: entourage,
                                       inviter: inviter,
                                       phone_number: phone_number,
                                       invitation_mode: EntourageInvitation::MODE_SMS)
      if invite.save
        callback.on_success.try(:call, invite)
      else
        callback.on_failure.try(:call, invite)
      end
    end

    private
    attr_reader :phone_number, :entourage, :callback, :inviter
  end
end