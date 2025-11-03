require 'google/apis/calendar_v3'
require 'googleauth'

GOOGLE_CALENDAR_SERVICE = Google::Apis::CalendarV3::CalendarService.new

unless EnvironmentHelper.test?
  begin
    credentials_json = ENV['BONNES_ONDES_SERVICE_ACCOUNT']
    email_account    = ENV['BONNES_ONDES_EMAIL_ACCOUNT']

    if credentials_json.blank? || email_account.blank?
      Rails.logger.warn('[GoogleCalendar] Missing configuration: BONNES_ONDES_SERVICE_ACCOUNT or BONNES_ONDES_EMAIL_ACCOUNT')
    else
      credentials = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(credentials_json),
        scope: [
          'https://www.googleapis.com/auth/calendar',
          'https://www.googleapis.com/auth/calendar.events',
          'https://www.googleapis.com/auth/meetings.space.created'
        ]
      )

      credentials.sub = email_account
      credentials.fetch_access_token!

      GOOGLE_CALENDAR_SERVICE.authorization = credentials
      Rails.logger.info('[GoogleCalendar] Google Calendar successfuly initialized')
    end
  rescue => e
    Rails.logger.error("[GoogleCalendar] Error : #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n")) if Rails.env.development?
  end
end
