require 'rails_helper'

describe CleanupService, type: :service do
  describe '.force_close_tours' do
    let! (:tour1) { create :tour, created_at:(Time.now - 5.hours), status: 'ongoing' }
    let! (:tour2) { create :tour, created_at:(Time.now - 4.hours), status: 'ongoing' }
    let! (:tour3) { create :tour, created_at:(Time.now - 3.hours), status: 'ongoing' }
    let! (:tour_point1) { create :tour_point, tour: tour1, passing_time: (Time.now - 4.hours) }
    let! (:tour_point2) { create :tour_point, tour: tour1, passing_time: (Time.now - 3.hours) }
    let! (:tour_point3) { create :tour_point, tour: tour2, passing_time: (Time.now - 3.hours) }
    let! (:tour_point4) { create :tour_point, tour: tour2, passing_time: (Time.now - 2.hours) }
    before { CleanupService.force_close_tours }
    it { expect(Tour.find(tour1.id).status).to eq 'closed' }
    it { expect(Tour.find(tour1.id).closed_at).to eq TourPoint.find(tour_point2.id).passing_time }
    it { expect(Tour.find(tour2.id).status).to eq 'closed' }
    it { expect(Tour.find(tour2.id).closed_at).to eq TourPoint.find(tour_point4.id).passing_time }
    it { expect(Tour.find(tour3.id).status).to eq 'ongoing' }
  end
end