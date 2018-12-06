module EntourageServices
  class BulkInvitationService
    def initialize(phone_numbers:, entourage:, inviter:)
      @phone_numbers = phone_numbers
      @entourage = entourage
      @callback = BulkInviteCallback.new
      @inviter = inviter
    end

    def send_invite
      yield callback if block_given?

      successfull_invites = []
      failed_invites = []

      phone_numbers.each do |phone_number|
        sms_invite(phone_number: phone_number).send_invite do |on|
          on.success do |invite|
            successfull_invites << phone_number
          end

          on.failure do |error|
            failed_invites << phone_number
          end

          on.not_authorised do
            return callback.on_not_authorised.try(:call)
          end
        end
      end

      if failed_invites.empty?
        callback.on_success.try(:call, successfull_invites)
      else
        callback.on_failure.try(:call, successfull_invites, failed_invites)
      end
    end

    private
    attr_reader :phone_numbers, :entourage, :callback, :inviter

    def sms_invite(phone_number:)
      phone_number = Phone::PhoneBuilder.new(phone: phone_number).format
      EntourageServices::SmsInvite.new(phone_number: phone_number, entourage: entourage, inviter: inviter)
    end

    class BulkInviteCallback < EntourageServices::SmsInviteCallback
    end
  end
end