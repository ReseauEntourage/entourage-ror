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

    def allowed_to_destroy?
      allowed_to_see? && tour.organization_name =~ /\AEntourage/
    end

    private
    attr_reader :user, :tour
  end
end
