class IraiserController < ActionController::Base
  def notification
    return render nothing: true

    raw_headers = Hash[env.select { |k, _| k.starts_with?('HTTP_') }.map { |k, v| [k[5..-1].tr('_', '-').capitalize, v] }]
    AsyncService.new(IraiserWebhookService).handle_notification(
      raw_headers,
      request.raw_post
    )
    render nothing: true
  end
end
