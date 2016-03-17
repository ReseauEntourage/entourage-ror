module TourServices
  class ToursUserStatus
    def initialize(tour_user:)
      @tour_user = tour_user
    end

    def accepted?
      tour_user.status=="accepted"
    end

    def pending?
      tour_user.status=="pending"
    end

    def rejected?
      tour_user.status=="rejected"
    end

    def accept!
      return true if accepted?

      ActiveRecord::Base.transaction do
        increment_counter
        tour_user.update!(status: "accepted")
      end

      PushNotificationService.new.send_notification(tour.user.full_name,
                                                    "Demande acceptée",
                                                    "Vous venez de rejoindre l'entourage de #{tour.user.organization_name}",
                                                    User.where(id: user.id),
                                                    {tour_id: tour.id})
      true
    end

    def reject!
      return true if rejected?

      if pending?
        tour_user.update(status: "rejected")
      elsif accepted?
        ActiveRecord::Base.transaction do
          decrement_counter
          tour_user.update!(status: "rejected")
        end
      end
    end

    def decrement_counter
      Tour.decrement_counter(:number_of_people, tour.id)
    end

    def increment_counter
      Tour.increment_counter(:number_of_people, tour.id)
    end

    def user
      tour_user.user
    end

    def tour
      tour_user.tour
    end

    private
    attr_reader :tour_user
  end
end