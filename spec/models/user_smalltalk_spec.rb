require 'rails_helper'

RSpec.describe UserSmalltalk, type: :model do
  describe '#save_match' do
    let(:smalltalk) { create(:smalltalk) }
    let(:user_1) { create(:user) }
    let(:user_2) { create(:user) }

    let(:user_smalltalk_1) { create(:user_smalltalk, user: user_1) }
    let(:user_smalltalk_2) { create(:user_smalltalk, user: user_2, smalltalk: smalltalk) }

    it 'associates user_smalltalk_1 to smalltalk from user_smalltalk_2 and create join_requests' do
      result = user_smalltalk_1.save_match(user_smalltalk_2)

      expect(result).to eq(smalltalk)
      expect(user_smalltalk_1.reload.smalltalk).to eq(smalltalk)
      expect(user_smalltalk_2.reload.smalltalk).to eq(smalltalk)

      expect(smalltalk.members).to include(user_1, user_2)
    end

    it 'creates smalltalk and associates both user_smalltalks' do
      user_smalltalk_1 = create(:user_smalltalk, user: create(:user))
      user_smalltalk_2 = create(:user_smalltalk, user: create(:user))

      expect { user_smalltalk_1.save_match(user_smalltalk_2) }.to change(Smalltalk, :count).by(1)
       .and change(JoinRequest, :count).by(2)

      expect(user_smalltalk_1.reload.smalltalk).to eq(user_smalltalk_2.reload.smalltalk)
    end

  end

  describe '#find_and_save_match!' do
    it 'calls save_match with first match' do
      user_smalltalk_1 = create(:user_smalltalk)
      user_smalltalk_2 = create(:user_smalltalk)

      allow(user_smalltalk_1).to receive(:find_matches).and_return([user_smalltalk_2])
      expect(user_smalltalk_1).to receive(:save_match).with(user_smalltalk_2)

      user_smalltalk_1.find_and_save_match!
    end

    it 'does not nothing whenever no match' do
      user_smalltalk_1 = create(:user_smalltalk)
      allow(user_smalltalk_1).to receive(:find_matches).and_return([])

      expect(user_smalltalk_1).not_to receive(:save_match)
      user_smalltalk_1.find_and_save_match!
    end
  end
end
