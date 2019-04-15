require 'mixpanel_tools'

class MixpanelService
  def initialize distinct_id:, default_properties:, event_prefix: nil
    @distinct_id = distinct_id
    @default_properties = default_properties.stringify_keys
    @event_prefix = event_prefix
  end

  attr_writer :distinct_id

  def distinct_id
    return @distinct_id if @distinct_id.present?

    warning_message = "distinct_id is not set yet"
    if Rails.env.in? %w(development test)
      raise warning_message
    else
      Rails.logger.warn "type=mixpanel.warning message=#{warning_message.inspect}"
    end

    nil
  end

  def track event, properties={}
    client.track(
      distinct_id,
      [@event_prefix, event].compact.join(" / "),
      @default_properties.merge(properties)
    )
  end

  def set properties
    client.people.set(
      distinct_id,
      properties,
      @default_properties['ip'] || '0'
    )
  end

  def set_once properties
    client.people.set_once(
      distinct_id,
      properties,
      @default_properties['ip'] || '0'
    )
  end

  def sync_changes user, props
    changes = {}
    (user.previous_changes.keys & props.keys).each do |changed_attr|
      changes[props[changed_attr]] = user[changed_attr]
    end
    if changes.any?
      set(changes)
    end
  end

  def client
    Rails.application.config.mixpanel
  end

  def self.sync_address address
    sync_addresses [address]
  end

  def self.sync_addresses addresses
    updates = addresses.lazy.map do |address|
      begin
        next if address.user.nil?
        {
          '$distinct_id' => address.user.id,
          '$set' => {
            "Zone d'action (pays)"        => address.country_name,
            "Zone d'action (code postal)" => address.postal_code,
            "Zone d'action (département)" => address.postal_code.first(2),
          }
        }
      rescue => e
        Raven.capture_exception(e)
      end
    end
    updates = updates.reject(&:nil?)
    MixpanelTools.batch_update(updates).to_a
  end
end
