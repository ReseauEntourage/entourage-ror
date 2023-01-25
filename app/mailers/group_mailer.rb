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
end
