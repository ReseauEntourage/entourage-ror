require 'rails_helper'

describe RecurrenceService do
  describe '.next_occurrence' do
    it 'advances by one day' do
      before = Time.zone.parse('2026-08-10 18:00')
      after = described_class.next_occurrence(before, :daily)

      expect(after.in_time_zone('Paris').strftime('%Y-%m-%d %H:%M')).to eq('2026-08-11 18:00')
    end

    it 'advances by one week' do
      before = Time.zone.parse('2026-08-10 18:00')
      after = described_class.next_occurrence(before, :weekly)

      expect(after.in_time_zone('Paris').strftime('%Y-%m-%d %H:%M')).to eq('2026-08-17 18:00')
    end

    it 'advances by one month' do
      before = Time.zone.parse('2026-08-10 18:00')
      after = described_class.next_occurrence(before, :monthly)

      expect(after.in_time_zone('Paris').strftime('%Y-%m-%d %H:%M')).to eq('2026-09-10 18:00')
    end

    it 'preserves the local wall-clock time across the spring DST transition (2026-03-29)' do
      before = Time.zone.parse('2026-03-28 18:00')
      after = described_class.next_occurrence(before, :daily)

      expect(after.in_time_zone('Paris').strftime('%H:%M')).to eq('18:00')
      expect(after.in_time_zone('Paris').to_date).to eq(Date.new(2026, 3, 29))
    end

    it 'preserves the local wall-clock time across the autumn DST transition (2026-10-25)' do
      before = Time.zone.parse('2026-10-24 18:00')
      after = described_class.next_occurrence(before, :daily)

      expect(after.in_time_zone('Paris').strftime('%H:%M')).to eq('18:00')
      expect(after.in_time_zone('Paris').to_date).to eq(Date.new(2026, 10, 25))
    end
  end
end
