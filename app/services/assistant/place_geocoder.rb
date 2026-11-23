module Assistant
  # Turns the text of a place or of a city, given by the assistant, into coordinates, with the
  # geocoder that the app already uses (Geocoder, see config/initializers/geocoder.rb).
  #
  # The text leaves Local for the geocoder: it is a point for the DPO (design.md, EN-9878). It is
  # only ever called with a text that the person gave: a city other than the one of their profile,
  # or the place of an outing they create. The text is not logged nor stored by Local.
  module PlaceGeocoder
    class NotFound < StandardError; end

    module_function

    # @return [Array(Float, Float)] latitude and longitude
    # @raise [NotFound] when the geocoder knows no such place. An error of the geocoder itself
    #   (network, quota) is not rescued: it is an failure of the action, not an unknown place.
    def locate text
      raise NotFound if text.blank?

      result = ::Geocoder.search(text.to_s.strip).find { |r| r.latitude.present? && r.longitude.present? }
      raise NotFound unless result

      [result.latitude.to_f, result.longitude.to_f]
    end
  end
end
