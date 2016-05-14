module EntourageServices
  class EntourageBuilder
    def initialize(params:, user:)
      @callback = Callback.new
      @params = params
      @user = user
    end

    def create
      yield callback if block_given?

      entourage = Entourage.new(params.except(:location))
      entourage.longitude = params.dig(:location, :longitude)
      entourage.latitude = params.dig(:location, :latitude)
      entourage.user = user

      if entourage.save
        #We you start a tour you are automatically added to members of the tour
        join_request = JoinRequest.create(joinable: entourage, user: user)
        TourServices::JoinRequestStatus.new(join_request: join_request).accept!
        callback.on_success.try(:call, entourage.reload)
      else
        callback.on_failure.try(:call, entourage)
      end
      tour
    end

    private
    attr_reader :tour, :user, :callback, :params
  end
end