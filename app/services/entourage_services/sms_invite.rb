module EntourageServices
  class SmsInvite
    def initialize(phone_number:, entourage:)
      @phone_number = phone_number
      @entourage = entourage
      @callback = Callback.new
    end

    def send_invite
      yield callback if block_given?
      invite = EntourageInvitation.new
      callback.on_success.try(:call, invite)
    end

    private
    attr_reader :phone_number, :entourage, :callback
  end
end