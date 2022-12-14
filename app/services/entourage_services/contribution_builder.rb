module EntourageServices
  class ContributionBuilder
    attr_reader :callback, :user, :params

    def initialize(params:, user:)
      @callback = Callback.new
      @params = params
      @user = user
    end

    def create
      yield callback if block_given?

      contribution = Contribution.new(params.except(:location))
      contribution.user = user
      contribution.status = :open
      contribution.longitude = params.dig(:location, :longitude)
      contribution.latitude = params.dig(:location, :latitude)
      contribution.group_type = :action
      contribution.entourage_type = :contribution
      contribution.public = true
      contribution.uuid = SecureRandom.uuid

      return callback.on_success.try(:call, contribution.reload) if contribution.save

      callback.on_failure.try(:call, contribution)
    end
  end
end
