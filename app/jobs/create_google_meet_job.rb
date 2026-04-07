class CreateGoogleMeetJob < ApplicationJob
  queue_as :default

  MAX_ATTEMPTS = 3

  def perform meeting_id, attempts = 1
    return unless meeting = Meeting.find_by(id: meeting_id)
    return if meeting.create_google_meet_event

    return unless attempts < MAX_ATTEMPTS

    self.class.set(wait: 2.minutes).perform_later(meeting_id, attempts + 1)
  end
end
