require 'rails_helper'

RSpec.describe TourPresenter do
  def duration_presenter(duration:)
    time = Time.parse("2010/10/10")
    tour = FactoryBot.build(:tour, created_at: time, closed_at: time+duration.seconds)
    tp1 = FactoryBot.create(:tour_point, tour: tour, created_at: time)
    tp2 = FactoryBot.create(:tour_point, tour: tour, created_at: (time+duration.seconds))
    TourPresenter.new(tour: tour)
  end

  def distance_presenter(distance:)
    TourPresenter.new(tour: FactoryBot.build(:tour, length: distance))
  end

  describe 'duration' do
    it { expect(duration_presenter(duration: 55).duration).to eq("environ 1 minute") }
    it { expect(duration_presenter(duration: 110).duration).to eq("environ 2 minutes") }
    it { expect(duration_presenter(duration: 3600).duration).to eq("1 heure 0 minutes") }
    it { expect(duration_presenter(duration: 3680).duration).to eq("1 heure 1 minute") }
    it { expect(duration_presenter(duration: 7899).duration).to eq("2 heures 11 minutes") }
  end

  describe 'distance' do
    it { expect(distance_presenter(distance: 110).distance).to eq("110 m") }
    it { expect(distance_presenter(distance: 3600).distance).to eq("3,6 km") }
    it { expect(distance_presenter(distance: 7899).distance).to eq("7,899 km") }
    it { expect(distance_presenter(distance: 67899).distance).to eq("67,9 km") }
    it { expect(distance_presenter(distance: 567899).distance).to eq("567,9 km") }
  end
end
