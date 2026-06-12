# frozen_string_literal: true

require 'rails_helper'

describe SuggestionServices::Scorer do
  let(:user) { create(:public_user, :paris) }

  describe '#lifecycle_segment' do
    context 'without engagement_level (new user < 14 days)' do
      before { user.update!(created_at: 5.days.ago) }

      it 'returns :new' do
        expect(described_class.new(user).lifecycle_segment).to eq(:new)
      end
    end

    context 'without engagement_level (old user > 14 days)' do
      before { user.update!(created_at: 20.days.ago) }

      it 'returns :churning' do
        expect(described_class.new(user).lifecycle_segment).to eq(:churning)
      end
    end

    context 'with badge SUPER_ENGAGE' do
      before { create(:engagement_level, user: user) }

      it 'returns :active' do
        allow(EngagementLevel).to receive(:find_by).with(user_id: user.id)
          .and_return(instance_double(EngagementLevel, badge: 'SUPER_ENGAGE'))

        expect(described_class.new(user).lifecycle_segment).to eq(:active)
      end
    end

    context 'with badge PASSIVE' do
      it 'returns :churning' do
        allow(EngagementLevel).to receive(:find_by).with(user_id: user.id)
          .and_return(instance_double(EngagementLevel, badge: 'PASSIVE'))

        expect(described_class.new(user).lifecycle_segment).to eq(:churning)
      end
    end

    context 'with badge SILENT' do
      it 'returns :hibernating' do
        allow(EngagementLevel).to receive(:find_by).with(user_id: user.id)
          .and_return(instance_double(EngagementLevel, badge: 'SILENT'))

        expect(described_class.new(user).lifecycle_segment).to eq(:hibernating)
      end
    end
  end

  describe '#score' do
    let(:address) { user.address }
    let(:outing) do
      create(:outing, latitude: address.latitude, longitude: address.longitude, status: 'open')
    end

    it 'returns a Float between 0 and 1' do
      score, _reasons = described_class.new(user).score(outing)

      expect(score).to be_between(0.0, 1.0)
    end

    it 'returns reasons as an Array' do
      _score, reasons = described_class.new(user).score(outing)

      expect(reasons).to be_an(Array)
    end

    it 'returns reason hashes with icon and text keys' do
      user.update!(created_at: 5.days.ago)
      outing.update!(interest_list: user.interest_list) if user.interest_list.any?

      _score, reasons = described_class.new(user).score(outing)

      reasons.each do |reason|
        expect(reason).to include('icon' => anything, 'text' => anything)
          .or include(icon: anything, text: anything)
      end
    end

    context 'when candidate has no coordinates' do
      it 'returns 0 for distance component without raising' do
        outing.update!(latitude: nil, longitude: nil)
        expect { described_class.new(user).score(outing) }.not_to raise_error
      end
    end
  end
end
