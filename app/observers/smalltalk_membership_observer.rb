class SmalltalkMembershipObserver < ActiveRecord::Observer
  observe :join_request

  def after_commit(join_request)
    return unless join_request.smalltalk?
    return unless join_request.previous_changes.key?('status') || join_request.previous_changes.key?('id')

    SmalltalkServices::MembershipMessager.new(join_request).run
  end
end
