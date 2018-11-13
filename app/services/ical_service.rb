module IcalService
  def self.generate_ical group, for_user: nil
    now = Time.now
    url = "#{ENV['WEBSITE_URL']}/entourages/#{group.uuid_v2}"

    cal = Icalendar::Calendar.new
    cal.prodid = '-//entourage.social//entourage-ror//FR'

    cal.publish

    cal.event do |e|
      e.uid = "#{group.uuid_v2}#{env_suffix}@entourage.social"

      e.dtstamp = utc(now)
      e.last_modified = utc(now)

      e.summary = group.title
      e.description = [group.description, url].compact.join("\n\n")
      e.url = url

      if for_user
        e.append_attendee Icalendar::Values::CalAddress.new(
          "mailto:#{for_user.email}",
          role: 'REQ-PARTICIPANT',
          partstat: 'NEEDS-ACTION',
          rsvp: 'TRUE'
        )
      end

      e.dtstart = utc(group.metadata[:starts_at].change(sec: 0))
      e.dtend   = utc(group.metadata[:starts_at].change(sec: 0).advance(hours: 2))

      e.location = group.metadata[:display_address]
      e.geo = [group.latitude.round(6), group.longitude.round(6)]

      e.status = 'CONFIRMED'
    end

    cal.to_ical
  end

  def self.file_name group
    attachment_name = [
      GroupService.name(group).capitalize.parameterize,
      '_',
      group.community.name.parameterize,
      '.ics'
    ].join
  end

  def self.attach_ical group:, to:, for_user: nil
    to.attachments[file_name(group)] = {
      mime_type: 'text/calendar; charset=UTF-8; method=PUBLISH',
      content: IcalService.generate_ical(group, for_user: for_user)
    }
  end

  def self.utc time
    Icalendar::Values::DateTime.new time.utc, 'tzid' => 'UTC'
  end

  def self.env_suffix
    if Rails.env != 'production'
      env = Rails.env
    elsif ENV['STAGING']
      env = 'preprod'
    end

    if env
      "-#{env}"
    else
      ''
    end
  end
end
