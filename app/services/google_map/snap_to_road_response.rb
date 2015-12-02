module GoogleMap
  class SnapToRoadResponse
    def initialize(json:)
      @json = json
    end

    def coordinates_only
      return [] if json.blank?

      json["snappedPoints"].map do |point|
        {lat: point["location"]["latitude"],
          long: point["location"]["longitude"]}
      end
    end

    private
    attr_reader :json
  end
end