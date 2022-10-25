module JoinRequestsServices
  class AdminAcceptedJoinRequestBuilder
    def initialize(joinable:, user:)
      @joinable = joinable
      @user     = user
    end

    def create
      return false unless @user.admin?

      join_request = JoinRequest.new(joinable: @joinable, user: @user,  status: JoinRequest::ACCEPTED_STATUS)

      join_request.role =
        case [joinable.community, joinable.group_type]
        when ['entourage', 'tour']   then 'member'
        when ['entourage', 'action'] then 'member'
        when ['entourage', 'outing'] then 'participant'
        when ['entourage', 'group']  then 'member'
        else raise 'Unhandled'
        end

      success = true
      ApplicationRecord.transaction do
        success &&= joinable.class.increment_counter(:number_of_people, joinable.id) == 1
        success &&= join_request.save
        raise ActiveRecord::Rollback unless success
      end

      join_request
    end

    private

    attr_reader :joinable
  end
end
