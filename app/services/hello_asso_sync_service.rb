# Syncs the public "Event" forms (billetterie) of one HelloAsso organization.
#
# Unlike OpenAgenda (one platform-wide public key can read any agenda by uid), HelloAsso scopes
# an organization's own client_id/client_secret to that organization only — reading every
# organization by a single key requires HelloAsso's "FormOpenDirectory" Partner privilege, granted
# through a business agreement (contact partenariats@helloasso.org), not a self-service signup.
# So for now ENV['HELLOASSO_CLIENT_ID']/['HELLOASSO_CLIENT_SECRET'] are expected to belong to
# Entourage's own HelloAsso organization (or, once/if a Partner agreement is signed, a
# platform-wide key) — `helloasso_organization_slug` alone then plays the exact same role as
# OpenAgenda's `agenda_uid`.
class HelloAssoSyncService < AssociationEventSyncService
  TIMEOUT = 15 # seconds
  MAX_EVENTS = 300 # cap on how many individual events we cache locally per source, mirrors OpenAgendaSyncService

  private

  def source_identifier
    @source.helloasso_organization_slug
  end

  def missing_identifier_message
    "Aucun identifiant d'organisation HelloAsso renseigné pour l'instant (slug de l'URL helloasso.com/associations/<slug>)"
  end

  def credentials_missing_message
    return if client_id.present? && client_secret.present?

    "Identifiants HelloAsso non configurés (ENV['HELLOASSO_CLIENT_ID'] / ENV['HELLOASSO_CLIENT_SECRET'])"
  end

  def client_id
    ENV['HELLOASSO_CLIENT_ID']
  end

  def client_secret
    ENV['HELLOASSO_CLIENT_SECRET']
  end

  def api_base
    ENV['HELLOASSO_API_BASE'].presence || 'https://api.helloasso.com'
  end

  def fetch_upcoming_events
    forms = list_public_event_forms
    forms.filter_map { |form| fetch_form_detail(form) }
  end

  def access_token
    @access_token ||= begin
      response = HTTParty.post(
        "#{api_base}/oauth2/token",
        body: { grant_type: 'client_credentials', client_id: client_id, client_secret: client_secret },
        timeout: TIMEOUT
      )

      raise SyncError, "authentification HelloAsso : réponse HTTP #{response.code}" unless response.code.to_i == 200

      response['access_token'].tap { |token| raise SyncError, 'authentification HelloAsso : pas de token retourné' if token.blank? }
    end
  end

  def auth_headers
    { 'Authorization' => "Bearer #{access_token}", 'User-Agent' => 'entourage-ror (helloasso-sync; +https://entourage.social)' }
  end

  def list_public_event_forms
    slug = @source.helloasso_organization_slug
    forms = []
    continuation_token = nil

    loop do
      response = HTTParty.get(
        "#{api_base}/v5/organizations/#{slug}/forms",
        query: { formTypes: 'Event', states: 'Public', pageSize: 100, continuationToken: continuation_token }.compact,
        headers: auth_headers,
        timeout: TIMEOUT,
        format: :json
      )

      raise SyncError, "réponse HTTP #{response.code}" unless response.code.to_i == 200

      page = Array(response['data'])
      forms.concat(page)

      continuation_token = response.dig('pagination', 'continuationToken')
      break if continuation_token.blank? || page.empty? || forms.size >= MAX_EVENTS
    end

    forms.first(MAX_EVENTS).select { |form| upcoming?(form) }
  rescue SyncError
    raise
  rescue => e
    raise SyncError, "#{e.class}: #{e.message}"
  end

  def upcoming?(form)
    end_date = form['endDate'] || form['startDate']
    end_date.blank? || end_date.to_time >= Time.zone.now
  rescue ArgumentError
    true # unparseable date: don't silently drop the event, let a moderator see it and judge
  end

  # The light "forms" listing has no price — fetch the public form detail (tiers) to determine
  # gratuité strictly (see the "prix libre" exclusion in the sync decision doc).
  #
  # `tiers` and `organizationName` are confirmed FormPublicModel fields from the official API
  # reference. `address` is not documented there for the Event type — confirm its exact shape
  # against a real sandbox response before relying on it, and adjust format_location/lat/long
  # below if the real field names differ.
  def fetch_form_detail(form)
    slug = @source.helloasso_organization_slug

    response = HTTParty.get(
      "#{api_base}/v5/organizations/#{slug}/forms/Event/#{form['formSlug']}/public",
      headers: auth_headers,
      timeout: TIMEOUT,
      format: :json
    )

    return form.merge('tiers' => []) unless response.code.to_i == 200

    form.merge(response.parsed_response.slice('tiers', 'organizationName', 'address'))
  rescue => e
    Rails.logger.warn "type=hello_asso_sync.form_detail_error source_id=#{@source.id} form_slug=#{form['formSlug']} error=#{e.message}"
    form.merge('tiers' => [])
  end

  def event_uid(raw_event)
    raw_event['formSlug']
  end

  def assign_attributes(association_event, raw_event)
    association_event.title          = raw_event['title'].presence || '(sans titre)'
    association_event.description    = raw_event['description']
    association_event.starts_at      = raw_event['startDate']
    association_event.ends_at        = raw_event['endDate']
    association_event.location       = format_location(raw_event['address'])
    association_event.is_free        = free?(raw_event['tiers'])
    association_event.organizer_name = raw_event['organizationName']
    association_event.latitude       = raw_event.dig('address', 'latitude')
    association_event.longitude      = raw_event.dig('address', 'longitude')
  end

  # A ticket tier priced at 0 is genuinely free; a "prix libre" tier (minAmount present, no fixed
  # price) is NOT strictly free (see the sync decision doc) — nil (unknown) only when there is no
  # ticket tier at all to judge from.
  def free?(tiers)
    return nil if tiers.blank?

    tiers.all? { |tier| tier['price'].to_i.zero? && tier['minAmount'].blank? }
  end

  def format_location(address)
    return nil if address.blank?

    [address['address'], address['zipCode'], address['city']].compact_blank.join(', ')
  end
end
