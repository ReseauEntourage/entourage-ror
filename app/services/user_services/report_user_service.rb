module UserServices
  class ReportUserService
    def initialize reported_user:, params:
      @reported_user = reported_user
      @params = params
      @message = params[:message]
      @signals = (params[:signals] || []) & Tag.signal_list
      @callback = Callback.new
    end

    def report reporting_user:
      yield callback if block_given?

      return callback.on_failure.try(:call, 'reporting_user can not be null') if reporting_user.nil?
      return callback.on_failure.try(:call, 'reported_user can not be null') if reported_user.nil?
      return callback.on_failure.try(:call, 'reported_user can not be self') if reported_user == reporting_user
      return callback.on_failure.try(:call, 'Signal is invalid') if params[:signals] && signals.none?
      return callback.on_failure.try(:call, 'Message is required') if params[:signals].nil? && message.blank?

      # ActiveJob can't serialize AnonymousUser, it's not an ActiveRecord model.
      reporting_user = reporting_user.token if reporting_user.anonymous?

      formatted_signals = translate_signals(params[:signals] || []).join(', ')

      SlackServices::SignalUser.new(
        reported_user: reported_user,
        reporting_user: reporting_user,
        message: message,
        signals: formatted_signals
      ).notify

      UserHistory.create({
        user_id: reported_user.id,
        updater_id: reporting_user.id,
        kind: 'signal-user',
        metadata: {
          message: message,
          signals: formatted_signals
        }
      })

      callback.on_success.try(:call)
    end

    def translate_signals signals
      signals.map { |signal| Tag.signal_t signal }
    end

    def formatted_signals
      @formatted_signals ||= translate_signals(signals || []).join(', ')
    end

    private
    attr_reader :params, :reported_user, :message, :signals, :callback
  end
end
