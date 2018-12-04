class MailjetController < ActionController::Base
  def event
    events = params[:_json] || []
    events.each do |event|
      AsyncService.new(MailjetService).handle_event(event)
    end
    render nothing: true
  end
end
