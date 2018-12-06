module GroupAccessService
  def self.can_read_public_content? user:, group:
    case group.status
    when 'blacklisted'
      false
    when 'suspended'
      user.admin? || join_request_status(user, group) == 'accepted'
    else
      true
    end
  end

  private

  def self.join_request_status user, group
    JoinRequest.where(user: user, joinable: group).pluck(:status).first
  end
end
