class GroupMailer < MailjetMailer
  def event_created_confirmation event
    event_creator = event.user

    IcalService.attach_ical(group: event, for_user: event_creator, to: self)

    mailjet_email(
      to: event_creator,
      campaign_name: :event_created_confirmation,
      template_id: 491291,
      variables: [
        event => [
          :entourage_title,
          :entourage_share_url,
        ],
        event_date_time: event.metadata_datetimes_formatted,
        event_place_name: event.metadata[:display_address],
      ]
    )
  end

  def event_reminder_participant join_request
    return # @see EN-4675

    participant = join_request.user
    event = join_request.joinable

    IcalService.attach_ical(group: event, for_user: participant, to: self)

    mailjet_email(
      to: participant,
      campaign_name: :event_reminder_participant,
      template_id: 491289,
      variables: [
        event => [
          :entourage_url,
          :entourage_title,
          :entourage_share_url,
        ],
        event_date_time: event.metadata_datetimes_formatted,
        event_place_name: event.metadata[:display_address],
      ]
    )
  end
end
