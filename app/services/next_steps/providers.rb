module NextSteps
  # The candidates of each suggestion type, already filtered by the exclusions
  # and ranked by the score (design.md, decisions 5, 6 and 12).
  class Providers
    # candidates read from the database per type, before ranking
    LIMIT = 50

    # section of a need → categories of lieux solidaires, in order of preference
    # (design.md, decision 12; ids of the `categories` table)
    SECTION_POI_CATEGORIES = {
      'services' => [43, 5, 63], # Laver son linge, S'orienter, Bagageries
      'clothes' => [61, 62], # Vêtements, matériel ; Boîtes à dons
      'equipment' => [61, 62],
      'hygiene' => [42, 40, 6] # Douches, Toilettes, S'occuper de soi
    }.freeze

    # NextStep kind of each type
    KINDS = {
      'outing' => 'outing',
      'outing_nearby' => 'outing',
      'papotage' => 'outing',
      'neighborhood' => 'neighborhood',
      'action' => 'action',
      'need_contribution' => 'action',
      'content_path' => 'content_path',
      'smalltalk' => 'smalltalk',
      'post_message' => 'post_message',
      'become_ambassador' => 'become_ambassador',
      'poi' => 'poi'
    }.freeze

    attr_reader :user, :exclusions, :need

    def initialize user, exclusions, need: nil
      @user = user
      @exclusions = exclusions
      @need = need
      @score = Score.new(user)
    end

    # @return [Array<Candidate>] best first
    def candidates type
      @candidates ||= {}
      @candidates[type] ||= send("#{type}_candidates")
    end

    private

    attr_reader :score

    def located?
      user.latitude.present? && user.longitude.present?
    end

    def bounding_box_sql latitude = user.latitude, longitude = user.longitude
      box = Geocoder::Calculations.bounding_box([latitude, longitude], UserService.travel_distance(user: user), units: :km)

      Geocoder::Sql.within_bounding_box(*box, :latitude, :longitude)
    end

    # --- events

    # In-person events of the zone, then online events; papotages excluded.
    def outing_candidates
      outing_nearby_candidates + rank_outings(upcoming_outings.where(online: true).where.not(id: papotage_ids))
    end

    # In-person events of the zone only (Dormant).
    def outing_nearby_candidates
      return [] unless located?

      rank_outings(upcoming_outings.where(online: false).where(bounding_box_sql).where.not(id: papotage_ids))
    end

    # The next papotages, soonest first: the fallback.
    def papotage_candidates
      upcoming_outings
        .where(id: papotage_ids)
        .limit(LIMIT)
        .map { |outing| Candidate.for_record('outing', outing, popularity: outing.number_of_people, latitude: nil, longitude: nil) }
    end

    def upcoming_outings
      outings = Outing
        .active
        .for_user(user)
        .future
        .where.not(user_id: user.id)
        .where(exclusions.not_joined_entourage_sql)
        .where.not(id: exclusions.excluded_target_ids('outing'))

      # same rule as groups (Neighborhood.not_reserved_female_for): no
      # women-only event for a man
      outings = outings.where("COALESCE(entourages.metadata->>'reserved_female', 'false') <> 'true'") if user.male?
      outings
    end

    def papotage_ids
      @papotage_ids ||= Papotages.ids(Outing.active.future)
    end

    def rank_outings scope
      outings = scope.limit(LIMIT).to_a
      interests = interests_by_id('Entourage', outings.map(&:id))

      score.rank(outings.map do |outing|
        Candidate.for_record('outing', outing,
          interest_list: interests[outing.id] || [],
          popularity: outing.number_of_people,
          latitude: outing.online? ? nil : outing.latitude,
          longitude: outing.online? ? nil : outing.longitude)
      end)
    end

    # --- groups

    # Groups of the zone; national groups on the user's interests when no
    # group of the zone fits.
    def neighborhood_candidates
      scope = Neighborhood
        .public_only
        .not_reserved_female_for(user)
        .where.not(id: exclusions.joined_neighborhood_ids + exclusions.excluded_target_ids('neighborhood'))

      local = located? ? rank_neighborhoods(scope.where(national: false).where(id: Neighborhood.inside_user_perimeter(user))) : []
      return local if local.any?

      national = scope.where(national: true)
      national = national.where(id: Neighborhood.match_at_least_one_interest(user.interest_list).select(:id)) if user.interest_list.any?

      rank_neighborhoods(national)
    end

    def rank_neighborhoods scope
      neighborhoods = scope.limit(LIMIT).to_a
      interests = interests_by_id('Neighborhood', neighborhoods.map(&:id))

      score.rank(neighborhoods.map do |neighborhood|
        Candidate.for_record('neighborhood', neighborhood,
          interest_list: interests[neighborhood.id] || [],
          popularity: neighborhood.number_of_people,
          latitude: neighborhood.national? ? nil : neighborhood.latitude,
          longitude: neighborhood.national? ? nil : neighborhood.longitude)
      end)
    end

    # --- entraides

    # Offers for a person in precarity, requests for the other profiles.
    def action_candidates
      rank_actions(user.is_ask_for_help? ? Contribution : Solicitation)
    end

    # Offers of the need's sections (need mode).
    def need_contribution_candidates
      return [] unless need&.sections.present?

      rank_actions(Contribution, sections: need.sections)
    end

    def rank_actions klass, sections: nil
      return [] unless located?

      scope = klass
        .active
        .where(bounding_box_sql)
        .where.not(user_id: [user.id] + exclusions.blocked_user_ids)
        .where.not(id: exclusions.excluded_target_ids('action'))
      scope = scope.where(id: klass.match_at_least_one_section(sections).select(:id)) if sections

      actions = scope.reorder(created_at: :desc).limit(LIMIT).to_a
      exclusions.joined_action_ids(actions.map(&:id))
      exclusions.preload_private_messages(actions.map(&:user_id))

      score.rank(actions.reject { |action| exclusions.answered_action?(action) }.map do |action|
        Candidate.for_record('action', action)
      end)
    end

    # --- contents

    # A mini-path of 3 unread contents, those pinned for the profile first, then
    # in publication order (resources have no editorial order: Resource.ordered
    # sorts on a position column that does not exist).
    def content_path_candidates
      resources = Resource.where.not(id: exclusions.excluded_resource_ids)
      ids = (resources.pin(user).order(:id).pluck(:id) + resources.order(:id).pluck(:id)).uniq.first(3)
      return [] if ids.size < 3

      [Candidate.new(kind: 'content_path', target_type: 'Resource', target_ids: ids)]
    end

    # --- gestures

    def smalltalk_candidates
      return [] if exclusions.smalltalk_recently_requested? || exclusions.excluded_gesture?('smalltalk')

      [Candidate.gesture('smalltalk')]
    end

    def become_ambassador_candidates
      return [] if exclusions.ambassador? || exclusions.excluded_gesture?('become_ambassador')

      [Candidate.gesture('become_ambassador')]
    end

    # Groups the user is a member of and never wrote in.
    def post_message_candidates
      neighborhoods = Neighborhood
        .where(id: exclusions.joined_neighborhood_ids)
        .where.not(id: exclusions.posted_neighborhood_ids + exclusions.excluded_target_ids('post_message'))
        .limit(LIMIT)
        .to_a

      score.rank(neighborhoods.map do |neighborhood|
        Candidate.for_record('post_message', neighborhood,
          popularity: neighborhood.number_of_people,
          latitude: neighborhood.national? ? nil : neighborhood.latitude,
          longitude: neighborhood.national? ? nil : neighborhood.longitude)
      end)
    end

    # --- lieux solidaires (need mode only)

    # Lieux of the first category, in order of preference, that has any.
    def poi_candidates
      return [] unless located? && need&.sections.present?

      need.sections.flat_map { |section| SECTION_POI_CATEGORIES.fetch(section, []) }.uniq.each do |category_id|
        pois = Poi
          .validated
          .with_category_ids([category_id])
          .where.not(latitude: nil)
          .where(bounding_box_sql)
          .where.not(id: exclusions.excluded_target_ids('poi'))
          .distinct
          .limit(LIMIT)
          .to_a

        return score.rank(pois.map { |poi| Candidate.for_record('poi', poi) }) if pois.any?
      end

      []
    end

    # --- helpers

    # interests of each record, from the taggings, in one query
    def interests_by_id taggable_type, ids
      return {} if ids.empty?

      ActsAsTaggableOn::Tagging
        .joins(:tag)
        .where(context: 'interests', taggable_type: taggable_type, taggable_id: ids)
        .pluck(:taggable_id, 'tags.name')
        .group_by(&:first)
        .transform_values { |pairs| pairs.map(&:last) }
    end
  end
end
