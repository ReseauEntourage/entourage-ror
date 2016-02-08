module TourServices
  class TourBuilder
    def initialize(params:, user:)
      @callback = TourServices::Callback.new
      @tour = user.tours.build(params.except(:distance))
      @tour.length = params[:distance]
      @user = user
    end

    def create
      yield callback if block_given?

      if tour.save
        #We you start a tour you are automatically added to members of the tour
        tours_user = ToursUser.create(tour: tour, user: user)
        TourServices::ToursUserStatus.new(tours_user: tours_user).accept!

        # When you start a tour we check if there was any messages scheduled to be delivered to people starting a tour on that day
        schedule_push_service = TourServices::SchedulePushService.new(organization: organization, date: Date.today)
        schedule_push_service.send_to(user)

        callback.on_create_success.try(:call, tour.reload)
      else
        callback.on_create_failure.try(:call, tour)
      end
      tour
    end

    private
    attr_reader :tour, :user, :callback

    def organization
      tour.user.organization
    end
  end

  class Callback
    attr_accessor :on_create_success, :on_create_failure

    def create_success(&block)
      @on_create_success = block
    end

    def create_failure(&block)
      @on_create_failure = block
    end
  end
end