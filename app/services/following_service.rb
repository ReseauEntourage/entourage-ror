module FollowingService
  def self.on_create_entourage(entourage)
    return unless entourage.invite_followers
    return unless partner = entourage.user.partner

    Following.where(partner_id: partner.id, active: true).preload(:user).find_each do |following|
      next if following.user == entourage.user
      EntourageServices::InviteExistingUser.new(
        entourage: entourage,
        inviter: entourage.user,
        invitee: following.user,
        mode: :partner_following
      ).send_invite
    end
  end
end
