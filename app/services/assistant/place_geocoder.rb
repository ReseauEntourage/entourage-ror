module Assistant
  # Turns the text of a place or of a city, given by the assistant, into coordinates, with the
  # geocoder that the app already uses (Geocoder, see config/initializers/geocoder.rb).
  #
  # The text leaves Local for the geocoder: it is a point for the DPO (design.md, EN-9878). It is
  # only ever called with a text that the person gave: a city other than the one of their profile,
  # or the place of an outing they create. The text is not logged nor stored by Local.
  module PlaceGeocoder
    class NotFound < StandardError; end

    # What the geocoder knows of a place: coordinates, formatted address and Google place id.
    Place = Struct.new(:latitude, :longitude, :address, :place_id, keyword_init: true)

    module_function

    # @return [Place]
    # @raise [NotFound] when the geocoder knows no such place. An error of the geocoder itself
    #   (network, quota) is not rescued: it is a failure of the action, not an unknown place.
    def locate text
      raise NotFound if text.blank?

      result = ::Assistant::Breadcrumbs.suppressed { ::Geocoder.search(text.to_s.strip) }.find { |r| r.latitude.present? && r.longitude.present? }
      raise NotFound unless result

      Place.new(
        latitude: result.latitude.to_f, longitude: result.longitude.to_f,
        address: (result.address if result.respond_to?(:address)).presence,
        place_id: (result.place_id if result.respond_to?(:place_id)).presence
      )
    end
  end
end
