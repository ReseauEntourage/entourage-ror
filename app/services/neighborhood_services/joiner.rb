module NeighborhoodServices
  class Joiner
    DEFAULT_BETA_TEST_NEIGHBORHOOD = 8

    attr_reader :user

    def initialize user
      @user = user
    end

    def join_default_beta_test!
      return unless default_beta_test
      return if JoinRequest.where(joinable: default_beta_test, user: user, status: :accepted).any?

      join_request = JoinRequest.find_or_initialize_by(joinable: default_beta_test, user: user)
      join_request.status = :accepted
      join_request.role = :member
      join_request.save
    end

    # temporary dev
    def default_beta_test
      @default_beta_test ||= Neighborhood.find_by_id(DEFAULT_BETA_TEST_NEIGHBORHOOD)
    end
  end
end
