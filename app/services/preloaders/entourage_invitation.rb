module Preloaders
  module EntourageInvitation
    # une requête pour toute la page, au lieu d'une par invitation (@see EntourageInvitation#join_request)
    def self.preload_join_requests invitations
      invitations = invitations.to_a
      return if invitations.empty?

      join_requests = ::JoinRequest
        .where(joinable_type: 'Entourage', joinable_id: invitations.map(&:invitable_id).uniq, user_id: invitations.map(&:invitee_id).uniq)
        .index_by { |join_request| [join_request.joinable_id, join_request.user_id] }

      invitations.each do |invitation|
        invitation.join_request = join_requests[[invitation.invitable_id, invitation.invitee_id]]
      end
    end
  end
end
