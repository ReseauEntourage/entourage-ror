module EntourageServices
  class InviteExistingUser

    def initialize(phone_number:, entourage:, inviter:, invitee:)
      @phone_number = phone_number
      @entourage = entourage
      @inviter = inviter
      @invitee = invitee
    end

    def send_invite
      invite = EntourageInvitation.where(invitable: entourage,
                                       inviter: inviter,
                                       phone_number: phone_number,
                                       invitation_mode: EntourageInvitation::MODE_SMS).first
      invite = create_invite! if invite.nil?
      notify_user!
      invite
    end

    private
    attr_reader :phone_number, :entourage, :inviter, :invitee

    def notify_user!
      if invitee.last_sign_in_at
        PushNotificationService.new.send_notification(inviter_name,
                                                      "Invitation à rejoindre un entourage",
                                                      "Vous ête invité à rejoindre l'entourage de #{inviter_name}",
                                                      User.where(id: invitee.id),
                                                      {
                                                          type: "ENTOURAGE_INVITATION",
                                                          entourage_id: entourage.id,
                                                          inviter_id: inviter.id,
                                                          invitee_id: invitee.id
                                                      })
      else
        SmsSenderJob.perform_later(phone_number, message)
      end
    end

    def create_invite!
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
        end
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n")
        return nil
      end
    end

    def inviter_name
      UserPresenter.new(user: invitee).display_name
    end

    def message
      "Bonjour, vous êtes invité à rejoindre un Entourage. Retrouvez l'application ici : #{link} ."
    end

    def link
      link = Rails.env.test? ? "http://foo.bar" : ShortURL.shorten(Rails.application.routes.url_helpers.store_redirection_url)
    end
  end
end