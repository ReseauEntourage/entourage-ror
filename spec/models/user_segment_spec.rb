require 'rails_helper'

RSpec.describe UserSegment, type: :model do
  it 'belongs to a user' do
    user_segment = create(:user_segment)

    expect(user_segment.user).to be_a(User)
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
