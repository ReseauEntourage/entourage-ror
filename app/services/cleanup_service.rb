class CleanupService
  def self.force_close_tours
    old_tours = Tour.where(status: Tour.statuses[:ongoing])
      .where('created_at <= ?', Time.now - 4.hours)

    old_tours.each do |t|
      TourServices::CloseTourService.new(tour: t).close!
      Rails.logger.warn "Force closing tour #{t}"
    end
  end
end
