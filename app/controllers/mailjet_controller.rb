class MailjetController < ActionController::Base
  # @see https://app.mailjet.com/account/triggers
  # a hook on mailjet sends notification using this controller to notify that a user has unsuscribe
  def event
    events = params[:_json] || []
    events.each do |event|
      MailjetService.handle_event(event.as_json)
    end
    head :ok
  end
end
