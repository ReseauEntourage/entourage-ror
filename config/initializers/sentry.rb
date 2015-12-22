require 'raven'

Raven.configure do |config|
  config.dsn = 'https://ce4de36ba0064487b646c7122c1e33c7:eebb8a0d464847268690f88e750b6f9b@app.getsentry.com/62022'
  config.environments = %w[ production ]
end