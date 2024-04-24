module EntourageServices
  class InviteNewUserBySms

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
        ApplicationRecord.transaction do
          invite.save!
          relationship.save!

          Rails.logger.info "InviteNewUserBySms : sending #{message} to #{phone_number}"
          SmsSenderJob.perform_later(phone_number, message, 'invite')
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
      @invitee = UserServices::PublicUserBuilder.new(params: {phone: phone_number}, community: entourage.community).create(send_sms: false, sms_code: @invitee_sms_code)
      raise ActiveRecord::RecordInvalid.new(@invitee) unless @invitee.valid?
      @invitee
    end

    def message
      @message ||= begin
        inviter_name = UserPresenter.new(user: inviter).display_name || 'un ami'
        inviter_name = sms_transliterate(inviter_name).truncate(32, omission: '..')
        "Bonjour, #{inviter_name} vous invite sur Entourage, le réseau solidaire. Votre code : #{invitee_sms_code}. Trouvez l'application ici : #{link}"
      end
    end

    SMS_CHARSET = "@£$¥èéùìòÇ\nØø\rÅåΔ_ΦΓΛΩΠΨΣΘΞÆæßÉ !\"#¤%&'()*+,-./0123456789:;<=>?¡ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑÜ`¿abcdefghijklmnopqrstuvwxyzäöñüà"
    def sms_transliterate string
      string.tr('’', '\'')
            .split('').map do |c|
              c.in?(SMS_CHARSET) ? c : ActiveSupport::Inflector.transliterate(c, '')
            end
            .join
    end

    def link
      link = Rails.env.test? ? 'http://foo.bar' : 'bit.ly/applientourage'
    end
  end
end
