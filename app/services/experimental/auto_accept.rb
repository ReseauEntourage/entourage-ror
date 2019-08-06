module Experimental::AutoAccept
  def self.accept join_request
    AsyncService.new(self)
      .set(wait_until: join_request.created_at + 15.seconds)
      .accept_now(join_request)
  end

  def self.accept_now join_request
    JoinRequestsServices::JoinRequestUpdater.new(
      join_request: join_request,
      status: 'accepted',
      message: nil,
      current_user: join_request.joinable.user
    ).update
  end

  def self.enable_callback
    !Rails.env.test?
  end

  module JoinRequestCallback
    extend ActiveSupport::Concern

    included do
      after_commit :auto_accept
    end

    private

    def auto_accept
      return unless Experimental::AutoAccept.enable_callback
      return unless (['id', 'status'] & previous_changes.keys).any?
      return unless status == JoinRequest::PENDING_STATUS
      return unless joinable.try(:auto_accept_join_requests?)
      Experimental::AutoAccept.accept(self)
    end
  end

  module Joinable
    def auto_accept_join_requests?
      user == ModerationServices.moderator(community: community)
    end
  end
end
