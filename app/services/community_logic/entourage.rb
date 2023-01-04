class CommunityLogic::Entourage < CommunityLogic::Common
  def self.group_created group
    case group.group_type
    when 'action'
      # do not send email anymore
    when 'outing' # event
      GroupMailer.event_created_confirmation(group).deliver_later
    else # not an action or an event. shouldn't happen.
      # nothing for now
    end
  end
end
