# https://github.com/alexreisner/geocoder/blob/v1.2.12/lib/geocoder/configuration.rb
Geocoder.configure(
  lookup: :google,

  google: {
    api_key: ENV['GOOGLE_API_KEY'],
    use_https: true,
    language: :fr,
  }
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
