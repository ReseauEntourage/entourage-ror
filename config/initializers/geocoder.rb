# https://github.com/alexreisner/geocoder/blob/v1.2.12/lib/geocoder/configuration.rb
Geocoder.configure(
  lookup: :google,
  api_key: ENV['GOOGLE_API_KEY'],
  use_https: true,
  language: :fr,

  # see https://github.com/alexreisner/geocoder/blob/v1.2.12/
  #   lib/geocoder/lookups/base.rb
  #   lib/geocoder/lookups/google.rb
  #   lib/geocoder/lookups/google.rb
  #
  # Ruby Socket exceptions including
  #   SocketError
  #   Errno::ECONNREFUSED
  #   TimeoutError
  #
  # Generic HTTP error codes
  #   Geocoder::InvalidRequest:      400
  #   Geocoder::RequestDenied:       401
  #   Geocoder::OverQueryLimitError: 402|429
  #   Geocoder::ServiceUnavailable:  503
  #
  # JSON parsing error
  #   Geocoder::ResponseParseError
  #
  # Google specific errors
  #   Geocoder::OverQueryLimitError
  #   Geocoder::RequestDenied
  #   Geocoder::InvalidRequest
  always_raise: :all
)

class Geocoder::Lookup::Base
  alias_method :_fetch_data, :fetch_data

  def fetch_data(query)
    begin
      Raven.breadcrumbs.record do |crumb|
        crumb.data = { text: query.text, options: query.options }
        crumb.category = 'geocoder.query'
      end
    rescue
    end
    response = _fetch_data(query)
    begin
      Raven.breadcrumbs.record do |crumb|
        crumb.data = { response: response }
        crumb.category = 'geocoder.response'
      end
    rescue
    end
    response
  end
end
