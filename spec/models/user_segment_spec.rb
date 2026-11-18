require 'rails_helper'

RSpec.describe UserSegment, type: :model do
  it 'belongs to a user' do
    user_segment = create(:user_segment)

    expect(user_segment.user).to be_a(User)
  end

  describe 'back-office filters' do
    let!(:dormant) { create(:user_segment, engagement_segment: 'Silencieux', engagement_sub_segment: 'Dormant') }
    let!(:a_activer) { create(:user_segment, engagement_segment: 'Silencieux', engagement_sub_segment: 'À activer') }
    let!(:pilier) { create(:user_segment, engagement_segment: 'Pilier') }
    let!(:unclassified) { create(:user_segment, engagement_segment: nil) }

    it 'matches a segment, whatever its sub-segment, or a sub-segment' do
      expect(UserSegment.matching('silencieux')).to contain_exactly(dormant, a_activer)
      expect(UserSegment.matching('dormant')).to contain_exactly(dormant)
      expect(UserSegment.matching('pilier')).to contain_exactly(pilier)
    end

    it 'filters the users through their segment' do
      expect(User.with_engagement_segment('silencieux')).to contain_exactly(dormant.user, a_activer.user)
      expect(User.with_engagement_segment('a_activer')).to contain_exactly(a_activer.user)
    end

    it 'gives the most precise key and the label of a segment' do
      expect([dormant, a_activer, pilier, unclassified].map(&:filter_key)).to eq(['dormant', 'a_activer', 'pilier', nil])
      expect([dormant, pilier, unclassified].map(&:label)).to eq(['Silencieux / Dormant', 'Pilier', nil])
    end
  end
end

RSpec.describe UserSegmentHistory, type: :model do
  it 'belongs to a user' do
    history = create(:user_segment_history)

    expect(history.user).to be_a(User)
  end

  describe '.open' do
    it 'returns only rows with no valid_to' do
      user = create(:user)
      closed = create(:user_segment_history, user: user, valid_from: 10.days.ago.to_date, valid_to: 1.day.ago.to_date)
      open = create(:user_segment_history, user: user, valid_from: Date.current, valid_to: nil)

      expect(UserSegmentHistory.open).to contain_exactly(open)
    end
  end
end
