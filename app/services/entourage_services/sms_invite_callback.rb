module EntourageServices
  class SmsInviteCallback < Callback
    attr_accessor :on_not_authorised

    def not_authorised(&block)
      @on_not_authorised = block
    end
  end
end