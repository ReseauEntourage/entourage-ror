require 'google/apis/calendar_v3'
require 'googleauth'

GOOGLE_CALENDAR_SERVICE = Google::Apis::CalendarV3::CalendarService.new

unless EnvironmentHelper.test?
  credentials = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: StringIO.new(ENV['BONNES_ONDES_SERVICE_ACCOUNT']),
    scope: [
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.events',
      'https://www.googleapis.com/auth/meetings.space.created'
    ]
  )

  credentials.sub = ENV['BONNES_ONDES_EMAIL_ACCOUNT']
  credentials.fetch_access_token!

  GOOGLE_CALENDAR_SERVICE.authorization = credentials
end
