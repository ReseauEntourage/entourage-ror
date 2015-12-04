module GoogleMap
  class SnapToRoadRequest
    def perform(coordinates:)
      url = build_url(coordinates: coordinates)
      body = snap_points(url: url)
      GoogleMap::SnapToRoadResponse.new(json: body)
    end

    def snap_points(url:)
      return if Rails.env.test?

      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      if response.code.to_i!= 200
        raise GoogleMap::SnapToRoadRequestError.new("Snap to road returned an unexpected response : #{response.code} - #{response.body}")
      end

      JSON.parse(response.body)
    end

    def build_url(coordinates:)
      path = coordinates.map {|coordinate| "#{coordinate[:lat]},#{coordinate[:long]}"}.join("|")
      interpolate = true
      key = ENV["ANDROID_GCM_API_KEY"]

      "https://roads.googleapis.com/v1/snapToRoads?" \
      "key=#{key}&" \
      "interpolate=#{interpolate}&" \
      "path=#{path}"
    end
  end

  class SnapToRoadRequestError < StandardError; end
end