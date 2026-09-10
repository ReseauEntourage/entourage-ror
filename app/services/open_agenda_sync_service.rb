class OpenAgendaSyncService
  API_BASE = 'https://api.openagenda.com/v2'.freeze
  TIMEOUT = 15 # seconds
  MAX_EVENTS = 300 # cap on how many individual events we cache locally per source

  class SyncError < StandardError; end

  def initialize(open_agenda_source)
    @source = open_agenda_source
  end

  # Fetches upcoming events for the agenda's UID via the OpenAgenda v2 API and upserts them
  # locally. Always leaves the source in a definite state (`exploitable` or `not_exploitable`)
  # with a human-readable reason on failure, mirroring IcalFeedSyncService.
  def sync!
    if @source.agenda_uid.blank?
      @source.update!(status: 'not_checked', last_checked_at: Time.zone.now, last_error: "Aucun identifiant d'agenda OpenAgenda renseigné pour l'instant")
      return
    end

    if public_key.blank?
      @source.update!(status: 'not_exploitable', last_checked_at: Time.zone.now, last_error: "Clé publique OpenAgenda non configurée (ENV['OPENAGENDA_PUBLIC_KEY'])")
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
      upcoming_events_count: @source.open_agenda_events.upcoming.count
    )
  rescue => e
    @source.update!(
      status: 'not_exploitable',
      last_checked_at: Time.zone.now,
      last_error: e.message.to_s.truncate(500)
    )
  end

  private

  def public_key
    ENV['OPENAGENDA_PUBLIC_KEY']
  end

  def fetch_upcoming_events
    response = HTTParty.get(
      "#{API_BASE}/agendas/#{@source.agenda_uid}/events",
      query: { key: public_key, relative: ['upcoming'], size: MAX_EVENTS },
      timeout: TIMEOUT,
      format: :json, # the real API serves a correct content-type, but don't rely on it — parse explicitly
      headers: { 'User-Agent' => 'entourage-ror (openagenda-sync; +https://entourage.social)' }
    )

    raise SyncError, "réponse HTTP #{response.code}" unless response.code.to_i == 200
    raise SyncError, response['message'].to_s if response['success'] == false

    Array(response['events'])
  rescue SyncError
    raise
  rescue => e
    raise SyncError, "#{e.class}: #{e.message}"
  end

  def upsert_events(events)
    events.uniq { |event| event['uid'] }.each do |event|
      uid = event['uid']
      next if uid.blank?

      open_agenda_event = @source.open_agenda_events.find_or_initialize_by(source_event_uid: uid)
      open_agenda_event.title         = event.dig('title', 'fr').presence || '(sans titre)'
      open_agenda_event.description   = event.dig('description', 'fr')
      open_agenda_event.starts_at     = event.dig('firstTiming', 'begin')
      open_agenda_event.ends_at       = event.dig('firstTiming', 'end')
      open_agenda_event.location      = format_location(event['location'])
      open_agenda_event.is_free       = event['nm-gratuit'] # organizer-specific custom field, often absent — nil means "unspecified", not "paid"
      open_agenda_event.organizer_name = event.dig('originAgenda', 'title')
      open_agenda_event.latitude      = event.dig('location', 'latitude')
      open_agenda_event.longitude     = event.dig('location', 'longitude')
      open_agenda_event.save!

      open_agenda_event.match_poi!
    end
  end

  def format_location(location)
    return nil if location.blank?

    [location['name'], location['address'], location['city']].compact_blank.join(', ')
  end

  def remove_events_no_longer_in_feed(events)
    kept_uids = events.map { |event| event['uid'] }.compact
    @source.open_agenda_events.where.not(source_event_uid: kept_uids).delete_all
  end
end
