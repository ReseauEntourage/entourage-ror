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
    Encounter.where('created_at <= ?', 48.hours.ago)
        .where('encrypted_message IS NOT NULL')
        .update_all(encrypted_message: nil)
  end
end
