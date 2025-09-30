class GroupMailer < MailjetMailer
  def event_created_confirmation event
    user = event.user

    IcalService.attach_ical(group: event, for_user: user, to: self)

    mailjet_email(
      to: user,
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

  def event_joined_confirmation event_id, user_id
    event = Outing.find(event_id)
    user = User.find(user_id)

    return if event.place_limit?

    IcalService.attach_ical(group: event, for_user: user, to: self)

    mailjet_email(
      to: user,
      campaign_name: :event_joined_confirmation,
      template_id: 6174412,
      variables: {
        outing: {
          name: event.title,
          address: event.metadata[:display_address],
          date: I18n.l(event.metadata[:starts_at].to_date, format: :long, locale: user.lang),
          hour: event.metadata[:starts_at].strftime("%Hh%M"),
          image_url: event.image_url_with_size(:landscape_url, :medium),
          calendar_url: event.calendar_url,
          url: event.share_url
        }
      }
    )
  end

  def event_participation_reminder event, user
    return if event.place_limit?

    mailjet_email(
      to: user,
      campaign_name: :event_participation_reminder,
      template_id: 6174429,
      variables: {
        outing: {
          name: event.title,
          address: event.metadata[:display_address],
          date: I18n.l(event.metadata[:starts_at].to_date, format: :long, locale: user.lang),
          hour: event.metadata[:starts_at].strftime("%Hh%M"),
          image_url: event.image_url_with_size(:landscape_url, :medium),
          calendar_url: event.calendar_url,
          url: event.share_url
        }
      }
    )
  end
end
