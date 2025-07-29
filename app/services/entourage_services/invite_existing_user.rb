module EntourageServices
  class InviteExistingUser

    def initialize(entourage:, inviter:, invitee:, mode: nil)
      @entourage = entourage
      @inviter = inviter
      @invitee = invitee
      @mode = (mode || EntourageInvitation::MODE_SMS).to_s
    end

    def send_invite
      invite =
        EntourageInvitation
        .where(
          invitable: entourage,
          inviter: inviter
        )
        .where('(invitee_id = ? OR phone_number = ?)', invitee.id, invitee.phone)
        .first
      if invite.nil?
        invite = create_invite!
      else
        invite.update(invitee: invitee, phone_number: invitee.phone)
      end

      invite
    end

    private
    attr_reader :entourage, :inviter, :invitee, :mode

    def create_invite!
      begin
        invite =
          EntourageInvitation
          .where(
            invitable: entourage,
            inviter: inviter,
            invitee: invitee,
          )
          .first_or_initialize do |invite|
            invite.phone_number = invitee.phone
            invite.invitation_mode = mode
          end
        relationship = UserRelationship.where(source_user: inviter,
                                            target_user: invitee,
                                            relation_type: UserRelationship::TYPE_INVITE).first_or_initialize
        ApplicationRecord.transaction do
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
      if mode == 'partner_following'
        inviter.partner.name
      else
        UserPresenter.new(user: inviter).display_name
      end
    end

    def message
      "Bonjour, vous êtes invité à rejoindre un Entourage. Retrouvez l'application ici : #{link} ."
    end

    def link
      link = Rails.env.test? ? 'http://foo.bar' : 'https://api.entourage.social/store_redirection'
    end
  end
end
