module EntourageServices
  class SolicitationBuilder
    attr_reader :callback, :user, :params

    def initialize(params:, user:)
      @callback = Callback.new
      @params = params
      @user = user
    end

    def create
      yield callback if block_given?

      solicitation = Solicitation.new(params.except(:location))
      solicitation.user = user
      solicitation.status = if solicitation.recipient_consent_obtained
        :open
      else
        :suspended
      end
      solicitation.longitude = params.dig(:location, :longitude)
      solicitation.latitude = params.dig(:location, :latitude)
      solicitation.group_type = :action
      solicitation.entourage_type = :ask_for_help
      solicitation.uuid = SecureRandom.uuid
      # category, display_category to be adapted with context
      solicitation.category = :social
      solicitation.display_category = :social

      return callback.on_success.try(:call, solicitation.reload) if solicitation.save

      callback.on_failure.try(:call, solicitation)
    end
  end
end
