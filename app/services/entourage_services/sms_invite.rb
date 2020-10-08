module EntourageServices
  class SmsInvite
    def initialize(phone_number:, entourage:, inviter:)
      @phone_number = phone_number
      @entourage = entourage
      @callback = EntourageServices::SmsInviteCallback.new
      @inviter = inviter
    end

    def send_invite
      yield callback if block_given?

      if entourage.status != 'open' && !inviter.admin?
        return callback.on_not_authorised.try(:call)
      end

      if JoinRequest.where(user: inviter, joinable: entourage, status: JoinRequest::ACCEPTED_STATUS).blank?
        return callback.on_not_authorised.try(:call)
      end

      if invitee
        invite = invite_existing_user.send_invite
      else
        invite = invite_new_user_by_sms.send_invite
      end

      if invite
        callback.on_success.try(:call, invite)
      else
        callback.on_failure.try(:call)
      end
    end

    private
    attr_reader :phone_number, :entourage, :callback, :inviter

    def invite_existing_user
      EntourageServices::InviteExistingUser.new(entourage: entourage, inviter: inviter, invitee: invitee)
    end

    def invite_new_user_by_sms
      EntourageServices::InviteNewUserBySMS.new(phone_number: phone_number, entourage: entourage, inviter: inviter)
    end

    def invitee
      User.where(phone: phone_number).first
    end
  end
end
