class MailjetController < ActionController::Base
  skip_before_action :verify_authenticity_token, only: [:event]

  # @see https://app.mailjet.com/account/triggers
  # a hook on mailjet sends notification using this controller to notify that a user has unsuscribe
  def event
    events = if params[:_json].is_a?(Array)
      params[:_json]
    else
      [params.except(:controller, :action, :mailjet)]
    end

    events.each do |event|
      MailjetService.handle_event(event.to_unsafe_h)
    end

    head :ok
  end

  # alias
  def events
    event
  end
end
