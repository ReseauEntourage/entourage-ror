class CreateGoogleMeetJob < ApplicationJob
  queue_as :default

  def perform meeting_id
    return unless meeting = Meeting.find_by(id: meeting_id)
    return if meeting.create_google_meet_event

    # retry unless successfully created
    self.class.set(wait: 2.minutes).perform_later(meeting_id)
  end
end
