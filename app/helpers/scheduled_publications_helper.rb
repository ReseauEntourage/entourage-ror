module ScheduledPublicationsHelper
  # @caution distance_of_time_in_words returns a bare duration ("6 jours") regardless of
  # direction - callers used to always prefix it with "dans", which reads backwards for a
  # publication stuck pending past its scheduled_at (e.g. a delayed worker) or for a failed one
  def scheduled_countdown(scheduled_at)
    return "aujourd'hui" if scheduled_at.to_date == Time.zone.now.to_date
    return "en retard de #{distance_of_time_in_words(scheduled_at, Time.zone.now)}" if scheduled_at.past?

    "dans #{distance_of_time_in_words(Time.zone.now, scheduled_at)}"
  end

  # @caution native date_field_tag/time_field_tag render per the browser's own language
  # settings, not the page's `lang` attribute - an admin with a non-French browser sees
  # mm/dd/yyyy and AM/PM regardless. A text field + the jQuery UI datepicker already bundled
  # (jquery-ui/datepicker-fr, cf. plugins.js) and plain <select>s are locale-independent.
  def scheduled_date_field(name, value: nil)
    text_field_tag(
      name, value&.strftime('%d/%m/%Y'),
      class: 'form-control js-datepicker', autocomplete: 'off', placeholder: 'jj/mm/aaaa'
    )
  end

  def scheduled_time_selects(name_prefix, value: nil)
    style = { class: 'form-control', style: 'display: inline-block; width: auto' }
    hours = (0..23).map { |h| format('%02d', h) }
    minutes = (0..59).map { |m| format('%02d', m) }

    hour_options = options_for_select(hours, value&.strftime('%H'))
    minute_options = options_for_select(minutes, value&.strftime('%M'))

    hour_select = select_tag("#{name_prefix}[scheduled_hour]", hour_options, style.merge(include_blank: 'HH'))
    minute_select = select_tag("#{name_prefix}[scheduled_minute]", minute_options, style.merge(include_blank: 'MM'))

    safe_join([hour_select, content_tag(:span, ' h ', style: 'margin: 0 4px'), minute_select])
  end
end
