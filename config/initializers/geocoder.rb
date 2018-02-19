# https://github.com/alexreisner/geocoder/blob/v1.2.12/lib/geocoder/configuration.rb
Geocoder.configure(
  lookup: :google,

  google: {
    api_key: ENV['GOOGLE_API_KEY'],
    use_https: true,
    language: :fr,
  }
)
