module JoinRequestsServices
  class JoinRequestBuilder
    def initialize(joinable:, user:, message:, distance:)
      @joinable = joinable
      @user = user
      @message = message
      @distance = distance
      @callback = Callback.new
    end

    def self.default_role joinable
      return 'member' if joinable.is_a?(Neighborhood)

      case [joinable.community, joinable.group_type]
        when ['entourage', 'tour']   then 'member'
        when ['entourage', 'action'] then 'member'
        when ['entourage', 'outing'] then 'participant'
        when ['entourage', 'group']  then 'member'
      else raise 'Unhandled'
      end
    end

    def create
      yield callback if block_given?

      join_request = JoinRequest.new(joinable: joinable, user: user, message: message, distance: distance)

      if !joinable.status.in?(['open', 'ongoing']) &&
         !user.admin?
        join_request.errors.add(:joinable, "is not opened (#{joinable.status})")
        return callback.on_failure.try(:call, join_request)
      end

      join_request.role = self.class.default_role(joinable)

      join_request.status = JoinRequest::ACCEPTED_STATUS if joinable.public

      if join_request.save
        callback.on_success.try(:call, join_request)
      else
        callback.on_failure.try(:call, join_request)
      end
    end

    private
    attr_reader :joinable, :callback, :user, :message, :distance
  end
end
