module TourServices
  class TourBuilder
    def initialize(params:, user:)
      @callback = Callback.new
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

        joinable = tour
        join_request.role =
          case [joinable.community, joinable.group_type]
          when ['entourage', 'tour']   then 'creator'
          when ['entourage', 'action'] then 'creator'
          else raise 'Unhandled'
          end

        TourServices::JoinRequestStatus.new(join_request: join_request).accept!

        callback.on_success.try(:call, tour.reload)
      else
        callback.on_failure.try(:call, tour)
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
end
