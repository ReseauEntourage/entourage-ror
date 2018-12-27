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
      return false if cancelled?

      ActiveRecord::Base.transaction do
        increment_counter
        join_request.update!(status: "accepted")
      end

      if user != joinable_author
        object = joinable.respond_to?(:title) ? joinable.title : "Demande acceptée"
        message = "Vous venez de rejoindre #{GroupService.name joinable, :l} de #{author_name}"

        PushNotificationService.new.send_notification(author_name,
                                                      object,
                                                      message,
                                                      User.where(id: user.id),
                                                      {
                                                          joinable_id: join_request.joinable_id,
                                                          joinable_type: join_request.joinable_type,
                                                          group_type: joinable.group_type,
                                                          type: "JOIN_REQUEST_ACCEPTED",
                                                          user_id: user.id
                                                      })

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
        ActiveRecord::Base.transaction do
          decrement_counter
          join_request.update!(status: "rejected")
        end
      end
      notify_owner(join_request.user, join_request.joinable.user, join_request.joinable)
      true
    end

    def quit!
      return true if cancelled?

      if pending?
        join_request.update(status: "cancelled")
      elsif accepted?
        ActiveRecord::Base.transaction do
          decrement_counter
          join_request.update!(status: "cancelled")
        end
      end
      notify_owner(join_request.user, join_request.joinable.user, join_request.joinable)
      true
    end

    def pending!
      return true if pending?

      if accepted?
        ActiveRecord::Base.transaction do
          decrement_counter
          join_request.update!(status: "pending")
        end
      elsif cancelled? && joinable.public?
        ActiveRecord::Base.transaction do
          increment_counter
          join_request.update!(status: "accepted")
        end
        JoinRequestsServices::JoinRequestBuilder.notify_auto_join_to_creator(join_request)
        true
      elsif cancelled?
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

    def notify_owner(requester, owner, joinable)
      if ENV["QUIT_ENTOURAGE_NOTIFICATION"]=="true"
        PushNotificationService.new.send_notification(UserPresenter.new(user: requester).display_name,
                                                      "Demande annulée",
                                                      "Demande annulée",
                                                      [owner],
                                                      {
                                                          joinable_id: joinable.id,
                                                          joinable_type: joinable.class.name,
                                                          group_type: joinable.group_type,
                                                          type: "JOIN_REQUEST_CANCELED",
                                                          user_id: requester.id
                                                      })
      end
    end
  end
end
