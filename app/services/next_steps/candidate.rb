module NextSteps
  # A possible suggestion, before it becomes a NextStep (hero) or is served as
  # one of the "others".
  #
  # - interest_list: nil when interests make no sense for the type
  # - popularity: nil when the type has no popularity
  # - latitude/longitude: nil when the target has no place (online, national)
  Candidate = Struct.new(
    :kind, :target, :target_type, :target_id, :target_ids,
    :latitude, :longitude, :interest_list, :popularity,
    :score, :score_components, :distance_km, :reason_codes,
    keyword_init: true
  )

  class Candidate
    def self.for_record kind, record, interest_list: nil, popularity: nil, latitude: record.try(:latitude), longitude: record.try(:longitude)
      new(
        kind: kind,
        target: record,
        target_type: NextStep::TARGET_TYPES.fetch(kind),
        target_id: record.id,
        target_ids: [],
        latitude: latitude,
        longitude: longitude,
        interest_list: interest_list,
        popularity: popularity
      )
    end

    def self.gesture kind
      new(kind: kind, target_ids: [])
    end

    # [kind, target_type, target_id]: what the exclusions and the "others"
    # diversity compare
    def key
      [kind, target_type, target_id]
    end
  end
end
