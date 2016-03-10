module TourUsersServices
  class TourUserBuilder
    def initialize(tour:, user:)
      @tour = tour
      @user = user
      @callback =TourUsersServices::Callback.new
    end

    def create
      yield callback if block_given?

      tour_user = ToursUser.new(tour: tour, user: user)
      if tour_user.save
        notify_tour_members
        callback.on_success.try(:call, tour_user)
      else
        callback.on_failure.try(:call, tour_user)
      end
    end

    private
    attr_reader :tour, :callback, :user

    def notify_tour_members
      recipients = tour.members.includes(:tours_users).where(tours_users: {status: "accepted"})
      PushNotificationService.new.send_notification(user.full_name,
                                                    "Demande en attente",
                                                    "Un nouveau membre souhaite rejoindre votre maraude",
                                                    recipients)
    end
  end

  class Callback
    attr_accessor :on_success, :on_failure

    def success(&block)
      @on_success = block
    end

    def failure(&block)
      @on_failure = block
    end
  end
end