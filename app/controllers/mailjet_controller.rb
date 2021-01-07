class MailjetController < ActionController::Base
  # @see https://app.mailjet.com/account/triggers
  # a hook on mailjet sends notification using this controller to notify that a user has unsuscribe
  def event
    events = params[:_json] || []
    events.each do |event|
      AsyncService.new(MailjetService).handle_event(event)
    end
    render nothing: true
  end
end
