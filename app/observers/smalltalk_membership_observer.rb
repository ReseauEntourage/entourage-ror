class SmalltalkMembershipObserver < ActiveRecord::Observer
  observe :join_request

  def after_commit join_request
    return unless join_request.smalltalk?
    return unless join_request.saved_change_to_status?

    SmalltalkServices::MembershipMessager.new(join_request).run
  end
end
