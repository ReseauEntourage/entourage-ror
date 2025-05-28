class Meeting < ApplicationRecord
  after_create :create_google_meet_event

  def create_google_meet_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: title,
      start: {
        date_time: start_time.iso8601,
        time_zone: 'Europe/Paris'
      },
      end: {
        date_time: end_time.iso8601,
        time_zone: 'Europe/Paris'
      },
      attendees: participant_emails.map { |email| { email: email } },
      conference_data: {
        create_request: {
          request_id: SecureRandom.uuid,
          conference_solution_key: { type: 'hangoutsMeet' }
        }
      }
    )

    created_event = GOOGLE_CALENDAR_SERVICE.insert_event(
      'primary',
      event,
      conference_data_version: 1
    )

    return unless created_event.respond_to?(:hangout_link)

    update!(meet_link: created_event.hangout_link)
  end
end
