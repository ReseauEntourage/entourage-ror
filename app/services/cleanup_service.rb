class CleanupService
  def self.force_close_tours
    old_tours = Tour.where(status: Tour.statuses[:ongoing])
      .where('created_at <= ?', Time.now - 4.hours)

    old_tours.each do |t|
      TourServices::CloseTourService.new(tour: t).close!
      Rails.logger.warn "Force closing tour #{t}"
    end
  end

  def self.force_resend_tour_reports
    old_tours = Tour.where(status: Tour.statuses[:closed], email_sent: false)
      .where('closed_at <= ?', Time.now - 4.hours)

    old_tours.each do |t|
      t.send_tour_report
      Rails.logger.warn "Force sending tour report #{t}"
    end
  end
end
