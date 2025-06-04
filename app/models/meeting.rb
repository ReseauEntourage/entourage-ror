class Meeting < ApplicationRecord
  after_create :create_google_meet_event

  def create_google_meet_event
    meeting_space = create_individual_meet_space

    if meeting_space
      created_event = create_calendar_event_with_space(meeting_space)
      update_meet_link(meeting_space['meetingUri'], created_event)
    else
      created_event = create_standard_calendar_event
      update_meet_link(nil, created_event)
    end
  end

  private

  def create_individual_meet_space
    auth_token = GOOGLE_CALENDAR_SERVICE.authorization.access_token

    space_config = {
      config: {
        access_type: 'OPEN',
        entry_point_access: 'ALL'
      }
    }

    response = HTTParty.post(
      'https://meet.googleapis.com/v2/spaces',
      headers: {
        'Authorization' => "Bearer #{auth_token}",
        'Content-Type' => 'application/json'
      },
      body: space_config.to_json
    )

    response.success? ? JSON.parse(response.body) : nil
  rescue
    nil
  end

  def create_calendar_event_with_space(meeting_space)
    meeting_uri = meeting_space['meetingUri']
    space_name = meeting_space['name']

    event = build_calendar_event({
      conference_id: space_name,
      signature: SecureRandom.uuid,
      entry_points: [
        {
          entry_point_type: 'video',
          uri: meeting_uri,
          label: 'Rejoindre avec Google Meet'
        }
      ]
    })

    GOOGLE_CALENDAR_SERVICE.insert_event('primary', event, conference_data_version: 1)
  end

  def create_standard_calendar_event
    event = build_calendar_event({
      create_request: {
        request_id: SecureRandom.uuid,
        conference_solution_key: { type: 'hangoutsMeet' }
      }
    })

    GOOGLE_CALENDAR_SERVICE.insert_event('primary', event, conference_data_version: 1)
  end

  def build_calendar_event(conference_data)
    Google::Apis::CalendarV3::Event.new(
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
      conference_data: conference_data
    )
  end

  def update_meet_link(meeting_uri, created_event)
    link = meeting_uri || created_event&.hangout_link
    update!(meet_link: link) if link
  end
end
