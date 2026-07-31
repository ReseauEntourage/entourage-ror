require 'rails_helper'

RSpec.describe ScheduledPublicationsHelper, type: :helper do
  describe '#scheduled_countdown' do
    it "says 'aujourd'hui' for a time later today" do
      expect(helper.scheduled_countdown(3.hours.from_now)).to eq("aujourd'hui")
    end

    it "says 'aujourd'hui' for a time earlier today" do
      expect(helper.scheduled_countdown(3.hours.ago)).to eq("aujourd'hui")
    end

    it 'prefixes a future date with "dans"' do
      expect(helper.scheduled_countdown(3.days.from_now)).to match(/\Adans /)
    end

    it 'prefixes an overdue date with "en retard de" instead of reading as if it were future' do
      expect(helper.scheduled_countdown(3.days.ago)).to match(/\Aen retard de /)
    end
  end
end
