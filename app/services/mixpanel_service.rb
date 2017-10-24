class MixpanelService
  def initialize distinct_id:, default_properties:, event_prefix: nil
    @distinct_id = distinct_id
    @default_properties = default_properties.stringify_keys
    @event_prefix = event_prefix
  end

  def track event, properties={}
    client.track(
      @distinct_id,
      [@event_prefix, event].compact.join(" / "),
      @default_properties.merge(properties)
    )
  end

  def client
    Rails.application.config.mixpanel
  end
end
