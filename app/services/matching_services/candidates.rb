module MatchingServices
  # Candidates of an action, selected in SQL around the place of the action.
  # Actions and outings go through the existing finders, and neighborhoods through the scopes of their finder,
  # so that their visibility rules apply (community, reserved_female, exclusive_to, groups already joined...).
  class Candidates
    Candidate = Struct.new(:record, :type, :distance_km, :freshness, :category_match, :similarity, :score, keyword_init: true)

    LIMIT_PER_TYPE = 100
    DEFAULT_DAYS = 30
    # points of interest are places people go to, often on foot
    POI_MAX_DISTANCE_KM = 5

    # sections of an action => ids of the categories of points of interest that can help (see PoiServices::SoliguideFormatter)
    POI_CATEGORY_IDS_BY_SECTION = {
      'clothes' => [61, 62, 43], # vêtements, boîtes à dons, laver son linge
      'equipment' => [61, 62, 63, 6], # vêtements et matériel, boîtes à dons, bagageries, s'occuper de soi
      'hygiene' => [40, 42, 43], # toilettes, douches, laver son linge
      'services' => [2, 3, 5, 7], # se loger, se soigner, s'orienter, se réinsérer
      'social' => [1, 5, 6] # se nourrir, s'orienter, s'occuper de soi
    }.freeze

    attr_reader :action, :user, :configuration

    def initialize action, configuration = nil
      @action = action
      @user = action.user
      @configuration = configuration
    end

    def all
      opposite_actions + outings + neighborhoods + pois + resources
    end

    def travel_distance
      @travel_distance ||= user.travel_distance || UserService::DEFAULT_DISTANCE
    end

    def self.starts_at outing
      starts_at = outing.starts_at

      starts_at.is_a?(String) ? Time.zone.parse(starts_at) : starts_at
    end

    private

    def finder_params
      @finder_params ||= {
        latitude: action.latitude,
        longitude: action.longitude,
        travel_distance: travel_distance
      }.compact
    end

    def opposite_actions
      finder = action.contribution? ? SolicitationServices::Finder : ContributionServices::Finder

      records = finder.new(user, finder_params).find_all
        .where('entourages.created_at > ?', days_for_actions.days.ago)
        .where.not(user_id: user.id)
        .limit(LIMIT_PER_TYPE)
        .to_a
      sections = tag_names(records, 'sections')

      records.map do |record|
        build(record, record.contribution? ? 'contribution' : 'solicitation',
          freshness: freshness(Time.current - record.created_at, days_for_actions),
          category_match: (sections.fetch(record.id, []) & action_sections).any?)
      end
    end

    def outings
      records = OutingsServices::Finder.new(user, finder_params).find_all
        .between(Time.zone.now, days_for_outings.days.from_now)
        .where.not(user_id: user.id)
        .limit(LIMIT_PER_TYPE)
        .to_a
      interests = tag_names(records, 'interests')

      records.map do |record|
        starts_at = self.class.starts_at(record)

        build(record, 'outing',
          distance: !record.online,
          freshness: starts_at && freshness(starts_at - Time.current, days_for_outings),
          category_match: (interests.fetch(record.id, []) & user_interests).any?)
      end
    end

    def neighborhoods
      # not NeighborhoodServices::Finder: its perimeter (ST_Transform) took up to 1 s to plan and its sort by
      # activity is useless here, together they hit the 2 s statement timeout on preprod
      box = Geocoder::Calculations.bounding_box([action.latitude, action.longitude], travel_distance, units: :km)

      records = Neighborhood
        .where(Geocoder::Sql.within_bounding_box(*box, :latitude, :longitude))
        .or(Neighborhood.where(national: true))
        .not_joined_by(user)
        .public_only
        .not_reserved_female_for(user)
        .order(proximity_order(:neighborhoods))
        .limit(LIMIT_PER_TYPE)
        .to_a
      interests = tag_names(records, 'interests')

      records.map do |record|
        build(record, 'neighborhood',
          distance: !record.national,
          category_match: (interests.fetch(record.id, []) & user_interests).any?)
      end
    end

    # points of interest are only recommended to people who ask for help
    def pois
      return [] if user.is_offer_help?
      return [] unless action.latitude && action.longitude

      category_ids = action_sections.flat_map { |section| POI_CATEGORY_IDS_BY_SECTION.fetch(section, []) }

      Poi.validated
        .around(action.latitude, action.longitude, [travel_distance, POI_MAX_DISTANCE_KM].min)
        .includes(:category, :categories)
        .order(proximity_order(:pois))
        .limit(LIMIT_PER_TYPE)
        .map do |record|
          build(record, 'poi', category_match: (([record.category_id] + record.category_ids) & category_ids).any?)
        end
    end

    def resources
      pinned_column = user.is_ask_for_help? ? :pin_ask_for_help : :pin_offer_help

      # some descriptions embed their images as data URIs (700 KB for one of them): only their text is used
      description = Arel.sql(%q{regexp_replace(resources.description, 'data:[^"'' )]+', '', 'g') AS description})

      Resource.select(*(Resource.column_names - ['description']), description).map do |record|
        build(record, 'resource', distance: false, category_match: record[pinned_column] == true)
      end
    end

    def build record, type, distance: true, freshness: nil, category_match: false
      Candidate.new(
        record: record,
        type: type,
        distance_km: distance ? distance_km(record) : nil,
        freshness: freshness,
        category_match: category_match
      )
    end

    def distance_km record
      return unless action.latitude && action.longitude && record.latitude && record.longitude

      Geocoder::Calculations.distance_between([action.latitude, action.longitude], [record.latitude, record.longitude], units: :km)
    end

    # 1 for something new (or about to happen), 0 at the end of the window
    def freshness seconds, days
      (1 - seconds / days.days.to_f).clamp(0, 1)
    end

    # squared equirectangular distance to the action: enough to sort by proximity, and much cheaper than ST_Distance
    def proximity_order table
      return Arel.sql("#{table}.id") unless action.latitude && action.longitude

      latitude = Float(action.latitude)
      longitude = Float(action.longitude)
      cosine = Math.cos(latitude * Math::PI / 180)

      Arel.sql("power(#{table}.latitude - #{latitude}, 2) + power((#{table}.longitude - #{longitude}) * #{cosine}, 2), #{table}.id")
    end

    # tag names by record id in one query, rather than one query per candidate
    def tag_names records, context
      return {} if records.empty?

      ActsAsTaggableOn::Tagging
        .joins(:tag)
        .where(taggable_type: records.first.class.polymorphic_name, taggable_id: records.map(&:id), context: context)
        .pluck(:taggable_id, 'tags.name')
        .group_by(&:first)
        .transform_values { |pairs| pairs.map(&:last) }
    end

    def action_sections
      @action_sections ||= action.section_list
    end

    def user_interests
      @user_interests ||= user.interest_list
    end

    def days_for_actions
      configuration&.days_for_actions || DEFAULT_DAYS
    end

    def days_for_outings
      configuration&.days_for_outings || DEFAULT_DAYS
    end
  end
end
