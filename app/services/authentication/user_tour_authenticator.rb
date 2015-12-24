module Authentication
  class UserTourAuthenticator
    def initialize(user:, tour:)
      @user = user
      @tour = tour
    end

    def allowed_to_see?
      tour.user == user
    end

    private
    attr_reader :user, :tour
  end
end