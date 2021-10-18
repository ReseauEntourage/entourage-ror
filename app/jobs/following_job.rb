class FollowingJob
  include Sidekiq::Worker

  def perform entourage_id, partner_id
    entourage = Entourage.find(entourage_id)

    Following.where(partner_id: partner_id, active: true).preload(:user).find_each do |following|
      next if following.user == entourage.user
      EntourageServices::InviteExistingUser.new(
        entourage: entourage,
        inviter: entourage.user,
        invitee: following.user,
        mode: :partner_following
      ).send_invite
    end
  end

  def self.perform_later(entourage)
    return unless entourage.invite_followers
    return unless partner = entourage.user.partner

    perform_async(entourage.id, partner.id)
  end
end
