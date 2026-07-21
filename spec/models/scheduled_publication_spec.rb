require 'rails_helper'

describe ScheduledPublication do
  describe 'validations' do
    it { should validate_presence_of(:scheduled_at) }
  end

  describe '#post?' do
    let(:scheduled_publication) { create(:scheduled_publication, :post) }

    it { expect(scheduled_publication.post?).to eq(true) }
    it { expect(scheduled_publication.broadcast?).to eq(false) }
  end

  describe '#broadcast?' do
    let(:scheduled_publication) { create(:scheduled_publication, :broadcast) }

    it { expect(scheduled_publication.broadcast?).to eq(true) }
    it { expect(scheduled_publication.post?).to eq(false) }
  end

  describe '.pending' do
    let!(:pending) { create(:scheduled_publication, :post, status: :pending) }
    let!(:published) { create(:scheduled_publication, :post, status: :published) }

    it { expect(ScheduledPublication.pending).to eq([pending]) }
  end

  describe '#in_the_past?' do
    it { expect(build(:scheduled_publication, :post, scheduled_at: 1.day.ago).in_the_past?).to eq(true) }
    it { expect(build(:scheduled_publication, :post, scheduled_at: 1.day.from_now).in_the_past?).to eq(false) }
  end
end
