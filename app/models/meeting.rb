class Meeting < ApplicationRecord
  after_create :create_google_meet_event

  def create_google_meet_event
    meeting_space = create_individual_meet_space

    unless meeting_space.present? && meeting_space['meetingUri'] && meeting_space['name']
      Rails.logger.error("Google Meet space creation failed: invalid or incomplete response") and return
    end

    created_event = create_calendar_event_with_space(meeting_space)

    unless created_event&.html_link
      Rails.logger.error("Google Calendar creation event failed") and return
    end

    update_meet_link(meeting_space['meetingUri'], created_event)
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

    if response.success?
      JSON.parse(response.body)
    else
      Rails.logger.error("API Meet error: #{response.code} - #{response.parsed_response}")
      nil
    end
  rescue => e
    Rails.logger.error("Meet space creation exception: #{e.class} - #{e.message}")
    nil
  end

  def create_calendar_event_with_space(meeting_space)
    meeting_uri = meeting_space['meetingUri']
    space_name  = meeting_space['name']

    entry_point = Google::Apis::CalendarV3::EntryPoint.new(
      entry_point_type: 'video',
      uri: meeting_uri,
      label: 'Rejoindre avec Google Meet'
    )

    conference_data = Google::Apis::CalendarV3::ConferenceData.new(
      conference_id: space_name,
      entry_points: [entry_point]
    )

    event = build_calendar_event(conference_data: conference_data)

    GOOGLE_CALENDAR_SERVICE.insert_event('primary', event, conference_data_version: 1)
  rescue Google::Apis::ClientError => e
    Rails.logger.error("Google API error: #{e.message}")
    nil
  end

  def build_calendar_event(conference_data:)
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
