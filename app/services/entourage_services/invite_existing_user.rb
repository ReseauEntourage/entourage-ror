module EntourageServices
  class InviteExistingUser

    def initialize(entourage:, inviter:, invitee:)
      @entourage = entourage
      @inviter = inviter
      @invitee = invitee
    end

    def send_invite
      invite = EntourageInvitation.where(invitable: entourage,
                                         inviter: inviter,
                                         invitee: invitee,
                                         invitation_mode: EntourageInvitation::MODE_SMS).first
      invite = create_invite! if invite.nil?
      notify_user!(invite: invite) unless invite.nil?
      invite
    end

    private
    attr_reader :entourage, :inviter, :invitee

    def notify_user!(invite:)
      if invitee.last_sign_in_at
        invitation_id = Rails.env.test? ? 123 : invite.id
        PushNotificationService.new.send_notification(inviter_name,
                                                      entourage.title,
                                                      "Vous êtes invité à rejoindre #{GroupService.name(entourage, :l)} de #{inviter_name}",
                                                      User.where(id: invitee.id),
                                                      {
                                                          type: "ENTOURAGE_INVITATION",
                                                          entourage_id: entourage.id,
                                                          group_type: entourage.group_type,
                                                          inviter_id: inviter.id,
                                                          invitee_id: invitee.id,
                                                          invitation_id: invitation_id
                                                      })
      else
        Rails.logger.info "InviteExistingUser : sending #{message} to #{invitee.phone}"
        SmsSenderJob.perform_later(invitee.phone, message, 'invite')
      end
    end

    def create_invite!
      begin
        invite = EntourageInvitation.where(invitable: entourage,
                                         inviter: inviter,
                                         invitee: invitee,
                                         phone_number: invitee.phone,
                                         invitation_mode: EntourageInvitation::MODE_SMS).first_or_initialize
        relationship = UserRelationship.where(source_user: inviter,
                                            target_user: invitee,
                                            relation_type: UserRelationship::TYPE_INVITE).first_or_initialize
        ActiveRecord::Base.transaction do
          invite.save!
          relationship.save!
        end
        invite
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n")
        return nil
      end
    end

    def inviter_name
      UserPresenter.new(user: inviter).display_name
    end

    def message
      "Bonjour, vous êtes invité à rejoindre un Entourage. Retrouvez l'application ici : #{link} ."
    end

    def link
      link = Rails.env.test? ? "http://foo.bar" : "https://api.entourage.social/store_redirection"
    end
  end
end
