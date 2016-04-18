module EntourageServices
  class SmsInvite
    def initialize(phone_number:, entourage:)
      @phone_number = phone_number
      @entourage = entourage
    end

    def send_invite

    end

    private
    attr_reader :phone_number, :entourage
  end
end