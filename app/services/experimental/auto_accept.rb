module Experimental::AutoAccept
  module Joinable
    def auto_accept_join_requests?
      user == ModerationServices.moderator(community: community)
    end
  end
end
