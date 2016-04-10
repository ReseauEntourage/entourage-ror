module TourServices
  class TourBuilder
    def initialize(params:, user:)
      @callback = TourServices::Callback.new
      @tour = user.tours.build(tour_params(params.except(:start_time)))
      @tour.created_at = params[:start_time] if params[:start_time]
      @tour.length = params[:distance]
      @user = user
    end

    def create
      yield callback if block_given?

      if tour.save
        #We you start a tour you are automatically added to members of the tour
        join_request = JoinRequest.create(joinable: tour, user: user)
        TourServices::JoinRequestStatus.new(join_request: join_request).accept!

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

    def tour_params(params)
      params[:status] = Tour.statuses[:ongoing]
      params.except(:distance)
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