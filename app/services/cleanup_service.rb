class CleanupService
  def self.force_close_tours
    old_tours = Tour.where(status: Tour.statuses[:ongoing])
      .where('created_at <= ?', Time.now - 4.hours)

    old_tours.each do |t|
      TourServices::CloseTourService.new(tour: t, params: nil).close!
      Rails.logger.warn "Force closing tour #{t}"
    end
  end

  def self.remove_old_encounter_message
    encounters =
      Encounter
        .where('created_at <= ?', 48.hours.ago)
        .where('encrypted_message IS NOT NULL OR '\
               'street_person_name IS NOT NULL OR '\
               'latitude IS NOT NULL')

    tour_ids = encounters.uniq.pluck(:tour_id)

    bins = {
      delete: [],
      keep:   []
    }

    tour_ids.each do |tour_id|
      report_emails = get_mailjet_messages(tour_id)
      next if report_emails.nil?

      email_status = Hash[report_emails.map { |m| [m.id, m.status] }]

      decision =
        if (email_status.values & ['sent', 'opened', 'clicked']).any?
          :delete
        else
          :keep
        end

      Rails.logger.info JSON.fast_generate(
        type: 'cleanup_service.remove_old_encounter_message',
        tour_id: tour_id,
        decision: decision,
        email_status: email_status
      )

      bins[decision].push tour_id
    end

    encounters
      .where(tour_id: bins[:delete])
      .update_all(encrypted_message: nil,
                  street_person_name: nil,
                  latitude: nil,
                  longitude:nil,
                  address: nil)

    send_slack_alert(bins[:keep]) if bins[:keep].any? &&  EnvironmentHelper.production?
  end

  def self.get_mailjet_messages tour_id
    report_emails = nil
    last_exception = nil

    3.times do
      begin
        report_emails = Mailjet::Message.all(custom_id: "tour_report-#{tour_id}")
        break
      rescue => e
        last_exception = e
      end
    end

    if report_emails.nil?
      Rails.logger.info JSON.fast_generate(
        type: 'cleanup_service.remove_old_encounter_message',
        error_class: last_exception.class.name,
        error_message: last_exception.message,
      )
    end

    report_emails
  end

  def self.send_slack_alert tour_ids
    return if ENV['SLACK_WEBHOOK_URL'].blank?

    Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL']).ping(
      text: "*Le compte-rendu de maraude n'a pas été délivré* après 48 h " \
            "pour les maraudes suivantes : _#{tour_ids.to_sentence}_.\n" \
            "Les données n'ont donc pas été effacées.",
      channel: '#mailjet-errors',
      username: 'Maraudes',
      icon_emoji: ':memo:'
    )
  end
end
