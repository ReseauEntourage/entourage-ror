require 'rails_helper'

describe RecurrenceRule do
  describe 'validations' do
    it { should validate_presence_of(:ends_on) }

    it { expect(build(:recurrence_rule, frequency: 'daily')).to be_valid }
    it { expect(build(:recurrence_rule, frequency: 'weekly')).to be_valid }
    it { expect(build(:recurrence_rule, frequency: 'monthly')).to be_valid }
    it { expect(build(:recurrence_rule, frequency: 'yearly')).not_to be_valid }
  end

  describe '#active?' do
    it { expect(build(:recurrence_rule, active: true).active?).to eq(true) }
    it { expect(build(:recurrence_rule, active: false).active?).to eq(false) }
  end
end
