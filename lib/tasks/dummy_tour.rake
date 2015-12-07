namespace :dummy_tour do
  desc "Creates a fake tour with random points around location"

  task :create, [:location] => [:environment] do |t, args|
    u = User.where(email: "vdaubry@gmail.com").first
    t = u.tours.create!(tour_type: "social", status: :closed, vehicle_type: :feet)
    coordinates = geocode_location(location: args[:location])
    20.times do
      longitude = coordinates["lng"]+rand(100) / 1000.0
      latitude = coordinates["lat"]+rand(100) / 1000.0
      t.snap_to_road_tour_points.create!(longitude: longitude, latitude: latitude)
    end

    SnapToRoadPolylineJob.perform_now(t.id)
  end


  def geocode_location(location:)
    require "net/https"
    require "uri"

    uri = URI.parse(geocode_url(location: location))
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    resp = JSON.parse(response.body)

    resp["results"][0]["geometry"]["location"]
  end

  def geocode_url(location:)
      key = ENV["ANDROID_GCM_API_KEY"]

      "https://maps.googleapis.com/maps/api/geocode/json?" \
      "address=#{location}&" \
      "key=#{key}&"
  end
end