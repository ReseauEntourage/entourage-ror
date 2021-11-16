module UserServices
  class ReportUserService
    def initialize(reported_user:, params:)
      @reported_user = reported_user
      @params = params
      @message = params[:message]
      @callback = Callback.new
    end

    def report(reporting_user:)
      yield callback if block_given?

      if reporting_user.nil? ||
         reported_user.nil? ||
         reported_user == reporting_user ||
         message.blank?

        return callback.on_failure.try(:call)
      end

      # ActiveJob can't serialize AnonymousUser, it's not an ActiveRecord model.
      reporting_user = reporting_user.token if reporting_user.anonymous?

      SlackServices::SignalUser.new(
        reported_user:  reported_user,
        reporting_user: reporting_user,
        message:        message
      ).notify

      UserHistory.create({
        user_id: reported_user.id,
        updater_id: reporting_user.id,
        kind: 'signal-user',
        metadata: {
          message: message
        }
      })

      callback.on_success.try(:call)
    end

    private
    attr_reader :reported_user, :message, :callback
  end
end
