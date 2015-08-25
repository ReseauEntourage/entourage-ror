require 'rails_helper'
require 'timecop'

RSpec.describe Tour, :type => :model do
  it { should validate_inclusion_of(:tour_type).in_array(%w(health friendly social food other)) }
  it { should define_enum_for(:vehicle_type) }
  it { should define_enum_for(:status) }
  it { should validate_presence_of(:tour_type) }
  it { should validate_presence_of(:vehicle_type) }
  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:user) }
  it { should belong_to(:user) }
  
  describe '#status=' do
    let!(:time) { DateTime.new 2015, 8, 25, 13, 11, 0 }
    before { Timecop.freeze(time) }
    after { Timecop.return }
    context 'closing' do
      let!(:tour) { Tour.new status: :ongoing, closed_at:nil }
      before { tour.status = 'closed' }
      it { expect(tour.closed_at).to eq time }
      it { expect(tour.status).to eq 'closed' }
    end
    context 'closing again' do
      let!(:other_time) { DateTime.new 2014, 8, 25, 13, 11, 0 }
      let!(:tour) { Tour.new status: :closed, closed_at: other_time }
      before { tour.status = 'closed' }
      it { expect(tour.closed_at).to eq other_time }
      it { expect(tour.status).to eq 'closed' }
    end
    context 'keeping ongoing' do
      let!(:tour) { Tour.new status: :ongoing, closed_at: nil }
      before { tour.status = 'ongoing' }
      it { expect(tour.closed_at).to be nil }
      it { expect(tour.status).to eq 'ongoing' }
    end
  end
  
  describe '#duration' do
    let!(:start) { Time.new 2015, 8, 25, 11, 5, 0 }
    let!(:now) { Time.new 2015, 8, 25, 13, 11, 0 }
    before { Timecop.freeze(now) }
    after { Timecop.return }
    context 'ongoing' do
      let!(:tour) { Tour.new created_at: start, closed_at:nil }
      it { expect(tour.duration).to eq(now - start) }
    end
    context 'closed' do
      let!(:stop) { Time.new 2015, 8, 25, 12, 8, 0 }
      let!(:tour) { Tour.new created_at: start, closed_at:stop }
      it { expect(tour.duration).to eq(stop - start) }
    end
  end
end
