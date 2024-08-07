module NeighborhoodServices
  class Joiner
    attr_reader :user

    def initialize user
      @user = user
    end

    def join_default_neighborhood!
      return unless default_neighborhood
      return if JoinRequest.where(joinable: default_neighborhood, user: user, status: [:accepted, :cancelled]).any?

      join_request = JoinRequest.find_or_initialize_by(joinable: default_neighborhood, user: user)
      join_request.status = :accepted
      join_request.role = :member
      join_request.save
    end

    def default_neighborhood
      @default_neighborhood ||= user.default_neighborhood
    end

    def default_neighborhood_as_member
      return default_neighborhood if JoinRequest.where(joinable: default_neighborhood, user: user, status: :accepted).any?

      nil
    end
  end
end
