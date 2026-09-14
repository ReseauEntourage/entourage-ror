class OpenAgendaSyncService < AssociationEventSyncService
  API_BASE = 'https://api.openagenda.com/v2'.freeze
  TIMEOUT = 15 # seconds
  MAX_EVENTS = 300 # cap on how many individual events we cache locally per source

  private

  def source_identifier
    @source.agenda_uid
  end

  def missing_identifier_message
    "Aucun identifiant d'agenda OpenAgenda renseigné pour l'instant"
  end

  def credentials_missing_message
    return if public_key.present?

    "Clé publique OpenAgenda non configurée (ENV['OPENAGENDA_PUBLIC_KEY'])"
  end

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

  def event_uid(raw_event)
    raw_event['uid']
  end

  def assign_attributes(association_event, raw_event)
    association_event.title          = raw_event.dig('title', 'fr').presence || '(sans titre)'
    association_event.description    = raw_event.dig('description', 'fr')
    association_event.starts_at      = raw_event.dig('firstTiming', 'begin')
    association_event.ends_at        = raw_event.dig('firstTiming', 'end')
    association_event.location       = format_location(raw_event['location'])
    association_event.is_free        = raw_event['nm-gratuit'] # organizer-specific custom field, often absent — nil means "unspecified", not "paid"
    association_event.organizer_name = raw_event.dig('originAgenda', 'title')
    association_event.latitude       = raw_event.dig('location', 'latitude')
    association_event.longitude      = raw_event.dig('location', 'longitude')
  end

  def format_location(location)
    return nil if location.blank?

    [location['name'], location['address'], location['city']].compact_blank.join(', ')
  end
end
