module TourServices
  class ToursUserStatus
    def initialize(tours_user:)
      @user = tours_user
    end

    def accepted?
      user.status=="accepted"
    end

    def pending?
      user.status=="pending"
    end

    def rejected?
      user.status=="rejected"
    end

    def accept!
      return true if accepted?

      ActiveRecord::Base.transaction do
        increment_counter
        user.update!(status: "accepted")
      end

      PushNotificationService.new.send_notification(user.full_name,
                                                    "Demande acceptée",
                                                    "Vous faites désormais partie de la mauraude",
                                                    recipients)
    end

    def reject!
      return true if rejected?

      if pending?
        user.update(status: "rejected")
      elsif accepted?
        ActiveRecord::Base.transaction do
          decrement_counter
          user.update!(status: "rejected")
        end
      end
    end

    def decrement_counter
      Tour.decrement_counter(:number_of_people, user.tour.id)
    end

    def increment_counter
      Tour.increment_counter(:number_of_people, user.tour.id)
    end

    private
    attr_reader :user
  end
end