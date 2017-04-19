module EntourageServices
  class InviteNewUserBySMS

    def initialize(phone_number:, entourage:, inviter:)
      @phone_number = phone_number
      @entourage = entourage
      @inviter = inviter
      @invitee_sms_code = UserServices::SmsCode.new.code
    end

    def send_invite
      begin
        invite = EntourageInvitation.new(invitable: entourage,
                                         inviter: inviter,
                                         invitee: invitee,
                                         phone_number: phone_number,
                                         invitation_mode: EntourageInvitation::MODE_SMS)
        relationship = UserRelationship.new(source_user: inviter,
                                            target_user: invitee,
                                            relation_type: UserRelationship::TYPE_INVITE)
        ActiveRecord::Base.transaction do
          invite.save!
          relationship.save!

          Rails.logger.info "InviteNewUserBySMS : sending #{message} to #{phone_number}"
          SmsSenderJob.perform_later(phone_number, message)
          invite
        end
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n")
        return nil
      end
    end

    private
    attr_reader :phone_number, :entourage, :inviter, :invitee_sms_code

    def invitee
      return @invitee if @invitee
      @invitee = UserServices::PublicUserBuilder.new(params: {phone: phone_number}).create(send_sms: false, sms_code: @invitee_sms_code)
      raise ActiveRecord::RecordInvalid.new(@invitee) unless @invitee.valid?
      @invitee
    end

    def message
      "Bonjour, vous êtes invité à rejoindre un Entourage. Votre code est #{invitee_sms_code}. Retrouvez l'application ici : #{link} ."
    end

    def link
      link = Rails.env.test? ? "http://foo.bar" : "https://api.entourage.social/store_redirection"
    end
  end
end
