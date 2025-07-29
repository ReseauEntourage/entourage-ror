raise 'HOST should be set' if ENV['HOST'].blank?
API_HOST = ENV['API_HOST'].presence || ENV['HOST']
ENV['WEBSITE_URL'] ||= 'https://www.entourage.social'
ENV['WEBSITE_APP_URL'] ||= 'https://app.entourage.social'
