module Authentication
  class UserTourAuthenticator
    def initialize(user:, tour:)
      @user = user
      @tour = tour
    end

    def allowed_to_see?
      return true if tour.user == user
      return true if user.manager && (user.organization == tour.user.organization)
      user.admin
    end

    private
    attr_reader :user, :tour
  end
end