# Shared sync contract for every AssociationEventSource provider (OpenAgenda, HelloAsso, ...):
# always leave the source in a definite state (`exploitable` or `not_exploitable`, or `not_checked`
# when no external identifier has been set yet) with a human-readable reason on failure — mirroring
# IcalFeedSyncService. Subclasses only implement the provider-specific pieces (identifier, HTTP
# fetch, and mapping a raw event to AssociationEvent attributes).
class AssociationEventSyncService
  class SyncError < StandardError; end

  def initialize(association_event_source)
    @source = association_event_source
  end

  def sync!
    if source_identifier.blank?
      @source.update!(status: 'not_checked', last_checked_at: Time.zone.now, last_error: missing_identifier_message)
      return
    end

    if (message = credentials_missing_message)
      @source.update!(status: 'not_exploitable', last_checked_at: Time.zone.now, last_error: message)
      return
    end

    events = fetch_upcoming_events

    upsert_events(events)
    remove_events_no_longer_in_feed(events)

    @source.update!(
      status: 'exploitable',
      last_checked_at: Time.zone.now,
      last_synced_at: Time.zone.now,
      last_error: nil,
      upcoming_events_count: @source.association_events.upcoming.count
    )
  rescue => e
    @source.update!(
      status: 'not_exploitable',
      last_checked_at: Time.zone.now,
      last_error: e.message.to_s.truncate(500)
    )
  end

  private

  # --- Provider-specific, implemented by subclasses ---

  def source_identifier
    raise NotImplementedError
  end

  def missing_identifier_message
    raise NotImplementedError
  end

  # Return an error message if the provider's credentials aren't configured, nil otherwise.
  def credentials_missing_message
    nil
  end

  # Must return an array of raw event hashes.
  def fetch_upcoming_events
    raise NotImplementedError
  end

  def event_uid(raw_event)
    raise NotImplementedError
  end

  def assign_attributes(association_event, raw_event)
    raise NotImplementedError
  end

  # --- Shared upsert/prune logic ---

  def upsert_events(events)
    events.uniq { |raw_event| event_uid(raw_event) }.each do |raw_event|
      uid = event_uid(raw_event)
      next if uid.blank?

      association_event = @source.association_events.find_or_initialize_by(source_uid: uid)
      association_event.provider = @source.provider
      assign_attributes(association_event, raw_event)
      association_event.save!

      association_event.match_poi!
    end
  end

  def remove_events_no_longer_in_feed(events)
    kept_uids = events.map { |raw_event| event_uid(raw_event) }.compact
    @source.association_events.where.not(source_uid: kept_uids).delete_all
  end
end
