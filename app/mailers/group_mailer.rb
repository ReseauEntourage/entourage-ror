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

  def event_joined_confirmation join_request
    return # @see EN-4675

    event = join_request.joinable
    new_member = join_request.user

    IcalService.attach_ical(group: event, for_user: new_member, to: self)

    mailjet_email(
      to: new_member,
      campaign_name: :event_joined_confirmation,
      template_id: 478397,
      variables: [
        event => [
          :entourage_title,
          :entourage_share_url,
        ],
        event_date_time: event.metadata_datetimes_formatted,
        event_place_name: event.metadata[:display_address],
        event_address_url: "https://www.google.com/maps/search/?api=1&query=#{event.metadata[:display_address]}&query_place_id=#{event.metadata[:google_place_id]}",
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
