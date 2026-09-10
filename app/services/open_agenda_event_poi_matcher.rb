class OpenAgendaEventPoiMatcher
  MATCH_RADIUS_KM = 0.1 # 100 metres : suffisant pour matcher un même bâtiment/adresse, évite les faux positifs
  BOUNDING_BOX_DELTA = 0.01 # ~1.1km : pré-filtre grossier (utilise l'index lat/long) avant le calcul exact de distance

  def initialize(open_agenda_event)
    @event = open_agenda_event
  end

  def match!
    source_poi_id = @event.open_agenda_source.poi_id

    if source_poi_id.present?
      @event.update!(poi_id: source_poi_id) unless @event.poi_id == source_poi_id
      return
    end

    poi = nearest_poi
    @event.update!(poi_id: poi&.id) unless @event.poi_id == poi&.id
  end

  private

  def nearest_poi
    return nil if @event.latitude.blank? || @event.longitude.blank?

    lat = @event.latitude
    lon = @event.longitude
    distance_expr = PostgisHelper.distance_from(lat, lon, 'pois')

    Poi.validated
       .where(latitude: (lat - BOUNDING_BOX_DELTA)..(lat + BOUNDING_BOX_DELTA))
       .where(longitude: (lon - BOUNDING_BOX_DELTA)..(lon + BOUNDING_BOX_DELTA))
       .where("(#{distance_expr}) <= ?", MATCH_RADIUS_KM)
       .order(Arel.sql(distance_expr))
       .first
  end
end
