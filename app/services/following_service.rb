module FollowingService
  def self.on_create_entourage(entourage_id)
    return unless entourage = Entourage.find_by_id(entourage_id)

    partner = entourage.user.partner

    return if partner.nil?

    followings = Following.where(partner_id: partner.id, active: true)
    followings.preload(:user).find_each do |following|
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
