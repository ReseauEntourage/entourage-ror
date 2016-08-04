module EntourageServices
  class SmsInviteCallback < Callback
    attr_accessor :on_not_part_of_entourage

    def not_part_of_entourage(&block)
      @on_not_part_of_entourage = block
    end
  end
end