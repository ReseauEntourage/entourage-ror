class CommunityLogic::Entourage < CommunityLogic::Common
  def self.group_created group
    case group.group_type
    when 'action'
      GroupMailer.action_confirmation(group).deliver_later
    when 'outing' # event
      GroupMailer.event_created_confirmation(group).deliver_later
    else # not an action or an event. shouldn't happen.
      # nothing for now
    end
  end

  def self.group_joined join_request
    group = join_request.joinable

    case group.group_type
    when 'outing' # event
      GroupMailer.event_joined_confirmation(join_request).deliver_later
    else
      # nothing for now
    end
  end

  def self.morning_emails
    at_day 1, before: :event, role: :organizer do |join_request|
      GroupMailer.event_reminder_organizer(join_request).deliver_later
    end

    at_day 1, before: :event, role: :participant do |join_request|
      GroupMailer.event_reminder_participant(join_request).deliver_later
    end

    at_day 1, after: :event, role: :organizer do |join_request|
      GroupMailer.event_followup_organizer(join_request).deliver_later
    end
  end
end
