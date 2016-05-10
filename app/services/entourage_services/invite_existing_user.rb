module EntourageServices
  class InviteExistingUser

    def initialize(phone_number:, entourage:, inviter:, invitee:)
      @phone_number = phone_number
      @entourage = entourage
      @inviter = inviter
      @invitee = invitee
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
          invite
        end
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n")
        return nil
      end
    end

    private
    attr_reader :phone_number, :entourage, :inviter, :invitee
  end
end