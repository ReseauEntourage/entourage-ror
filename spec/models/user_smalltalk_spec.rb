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

  describe 'finders' do
    let(:address_1) { create :address, latitude: 48.8566, longitude: 2.3522 }
    let(:address_2) { create :address, latitude: 48.8570, longitude: 2.3510 }
    let(:address_3) { create :address, latitude: 45.7500, longitude: 4.8500 }

    let(:user_1) { create(:user, address: address_1, addresses: [address_1], interests: ['jeux']) }
    let(:user_2) { create(:user, address: address_2, addresses: [address_2], interests: ['jeux', 'cuisine']) }
    let(:user_3) { create(:user, address: address_3, addresses: [address_3], interests: ['cuisine']) }

    let!(:user_smalltalk_1) { create(:user_smalltalk, user: user_1, match_format: :many, match_locality: true, match_interest: true) }
    let!(:user_smalltalk_2) { create(:user_smalltalk, user: user_2, match_format: :many) }
    let!(:user_smalltalk_3) { create(:user_smalltalk, user: user_3, match_format: :many) }

    describe '#find_matches' do
      it 'applies filters' do
        result_ids = user_smalltalk_1.find_matches.map(&:id)
        expect(result_ids).to include(user_smalltalk_2.id)
        expect(result_ids).not_to include(user_smalltalk_3.id)
      end
    end

    describe '#filter_by_locality' do
      it 'user_smalltalks within 20km' do
        scope = UserSmalltalk.not_matched.where.not(user_id: user_smalltalk_1.user_id)
        filtered = user_smalltalk_1.send(:filter_by_locality, scope)
        expect(filtered).to include(user_smalltalk_2)
        expect(filtered).not_to include(user_smalltalk_3)
      end
    end

    describe '#filter_by_common_interests' do
      it 'user_smalltalks with at least one common interest' do
        scope = UserSmalltalk.not_matched
        filtered = user_smalltalk_1.send(:filter_by_common_interests, scope)
        expect(filtered).to include(user_smalltalk_2)
        expect(filtered).not_to include(user_smalltalk_3)
      end
    end

    describe '#find_match' do
      it { expect(user_smalltalk_1.find_match.id).to eq(user_smalltalk_2.id) }
    end

    describe '#find_matches_count_by' do
      let(:count) { user_smalltalk_1.find_matches_count_by(criteria) }

      context "valid criteria" do
        let(:criteria) { :match_format }

        it { expect(count).to be_a(Hash) }
      end

      context "invalid criteria" do
        let(:criteria) { :invalid }

        it { expect { user_smalltalk_1.find_matches_count_by(:invalid) }.to raise_error(ArgumentError) }
      end
    end

    describe '#find_and_save_match!' do
      it 'sauvegarde un match et met à jour les relations' do
        expect { user_smalltalk_1.find_and_save_match! }.to change { Smalltalk.count }.by(1)
          .and change { UserSmalltalk.where.not(smalltalk_id: nil).count }.by(2)
      end
    end
  end
end
