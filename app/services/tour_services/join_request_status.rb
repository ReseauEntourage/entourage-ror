module TourServices
  class JoinRequestStatus
    def initialize(join_request:)
      @join_request = join_request
    end

    def accepted?
      join_request.status=="accepted"
    end

    def pending?
      join_request.status=="pending"
    end

    def rejected?
      join_request.status=="rejected"
    end

    def cancelled?
      join_request.status=="cancelled"
    end

    def accept!
      return true if accepted?

      ApplicationRecord.transaction do
        increment_counter
        join_request.update!(status: "accepted")
      end

      if user != joinable_author
        CommunityLogic.for(joinable).group_joined(join_request)
      end

      true
    end

    def reject!
      return true if rejected?
      return false if cancelled?

      if pending?
        join_request.update(status: "rejected")
      elsif accepted?
        ApplicationRecord.transaction do
          decrement_counter
          join_request.update!(status: "rejected")
        end
      end

      true
    end

    def quit!
      return true if cancelled?

      if pending?
        join_request.update(status: "cancelled")
      elsif accepted?
        ApplicationRecord.transaction do
          decrement_counter
          join_request.update!(status: "cancelled")
        end
      end

      true
    end

    def pending!
      return true if pending?

      if accepted?
        ApplicationRecord.transaction do
          decrement_counter
          join_request.update!(status: "pending")
        end
      elsif joinable.public?
        ApplicationRecord.transaction do
          increment_counter
          join_request.update!(status: "accepted")
        end
        JoinRequestsServices::JoinRequestBuilder.notify_auto_join_to_creator(join_request)
        true
      else
        join_request.update(status: "pending")
      end
    end

    def decrement_counter
      if accepted?
        joinable.class.decrement_counter(:number_of_people, joinable.id)
      end
    end

    def increment_counter
      return true if accepted?
      joinable.class.increment_counter(:number_of_people, joinable.id)
    end

    def user
      join_request.user
    end

    def joinable
      join_request.joinable
    end

    def joinable_author
      joinable.user
    end

    def author_name
      UserPresenter.new(user: joinable_author).display_name
    end

    private

    attr_reader :join_request
  end
end
