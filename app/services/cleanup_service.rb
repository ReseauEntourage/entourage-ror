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
        .where('encrypted_message IS NOT NULL OR '\
               'street_person_name IS NOT NULL OR '\
               'latitude IS NOT NULL')
        .update_all(encrypted_message: nil,
                    street_person_name: nil,
                    latitude: nil,
                    longitude:nil,
                    address: nil)
  end
end
