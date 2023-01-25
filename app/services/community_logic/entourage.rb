class CommunityLogic::Entourage < CommunityLogic::Common
  def self.group_created group
    return unless group.group_type == 'outing'

    GroupMailer.event_created_confirmation(group).deliver_later
  end
end
