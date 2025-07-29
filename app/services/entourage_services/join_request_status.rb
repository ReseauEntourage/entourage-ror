module EntourageServices
  class JoinRequestStatus
    def initialize(join_request:)
      @join_request = join_request
    end

    def accepted?
      join_request.status=='accepted'
    end

    def pending?
      join_request.status=='pending'
    end

    def rejected?
      join_request.status=='rejected'
    end

    def cancelled?
      join_request.status=='cancelled'
    end

    def accept!
      return true if accepted?

      join_request.update!(status: 'accepted')

      true
    end

    def reject!
      return true if rejected?
      return false if cancelled?

      if pending?
        join_request.update(status: 'rejected')
      elsif accepted?
        join_request.update!(status: 'rejected')
      end

      true
    end

    def quit!
      return true if cancelled?

      if pending?
        join_request.update(status: 'cancelled')
      elsif accepted?
        join_request.update!(status: 'cancelled')
      end

      true
    end

    def pending!
      return true if pending?

      if accepted?
        join_request.update!(status: 'pending')
      elsif joinable.public?
        join_request.update!(status: 'accepted')

        JoinRequestsServices::JoinRequestBuilder.notify_auto_join_to_creator(join_request)

        true
      else
        join_request.update(status: 'pending')
      end
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
