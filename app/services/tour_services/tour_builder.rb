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
        schedule_push_service = TourServices::SchedulePushService.new(organization: organization, date: Date.today)
        schedule_push_service.send_to(user)
        callback.on_create_success.try(:call, tour)
      else
        callback.on_create_failure.try(:call, tour)
      end
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