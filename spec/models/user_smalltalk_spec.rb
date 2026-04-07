require 'rails_helper'

RSpec.describe UserSmalltalk, type: :model do
  let!(:user_smalltalk_1) { create(:user_smalltalk, user: create(:user, :ask_for_help)) }
  let!(:user_smalltalk_2) { create(:user_smalltalk, user: create(:user, :offer_help)) }

  describe 'find_match' do
    let(:result) { user_smalltalk_1.find_match }

    describe 'format' do
      it { expect(result).to be_truthy }

      context 'match none when has already been matched' do
        before { user_smalltalk_2.update(smalltalk: create(:smalltalk)) }

        it { expect(result).to be_falsy }
      end

      context 'match none when different format' do
        before {
          user_smalltalk_1.update(match_format: :one)
          user_smalltalk_2.update(match_format: :many)
        }

        it { expect(result).to be_falsy }
      end

      context 'match one with no constraint' do
        before {
          user_smalltalk_1.update(match_format: :one)
          user_smalltalk_2.update(match_format: :one)
        }

        it { expect(result).to be_truthy }
      end
    end

    describe 'locality' do
      context 'match none when different locality' do
        before {
          user_smalltalk_1.update(match_locality: true, user_latitude: 0, user_longitude: 0)
          user_smalltalk_2.update(match_locality: true, user_latitude: 10, user_longitude: 10)
        }

        it { expect(result).to be_falsy }
      end

      context 'match one with same locality' do
        before {
          user_smalltalk_1.update(match_locality: true, user_latitude: 0, user_longitude: 0)
          user_smalltalk_2.update(match_locality: true, user_latitude: 0, user_longitude: 0)
        }

        it { expect(result).to be_truthy }
      end

      context 'match one with closed locality' do
        before {
          user_smalltalk_1.update(match_locality: true, user_latitude: 0, user_longitude: 0)
          user_smalltalk_2.update(match_locality: true, user_latitude: 0, user_longitude: 0.01)
        }

        it { expect(result).to be_truthy }
      end

      context 'match one with same locality and one does not care' do
        before {
          user_smalltalk_1.update(match_locality: true, user_latitude: 0, user_longitude: 0)
          user_smalltalk_2.update(match_locality: false, user_latitude: 0, user_longitude: 0)
        }

        it { expect(result).to be_truthy }
      end

      context 'match none with different locality and one does care' do
        before {
          user_smalltalk_1.update(match_locality: true, user_latitude: 0, user_longitude: 0)
          user_smalltalk_2.update(match_locality: false, user_latitude: 10, user_longitude: 10)
        }

        it { expect(result).to be_falsy }
      end
    end

    describe 'gender' do
      context 'match none when different gender' do
        before {
          user_smalltalk_1.update(match_gender: true, user_gender: :male)
          user_smalltalk_2.update(match_gender: true, user_gender: :female)
        }

        it { expect(result).to be_falsy }
      end

      context 'match one with same gender' do
        before {
          user_smalltalk_1.update(match_gender: true, user_gender: :male)
          user_smalltalk_2.update(match_gender: true, user_gender: :male)
        }

        it { expect(result).to be_truthy }
      end

      context 'match one with same gender and one does not care' do
        before {
          user_smalltalk_1.update(match_gender: true, user_gender: :male)
          user_smalltalk_2.update(match_gender: false, user_gender: :male)
        }

        it { expect(result).to be_truthy }
      end

      context 'match none with different gender and one does care' do
        before {
          user_smalltalk_1.update(match_gender: true, user_gender: :female)
          user_smalltalk_2.update(match_gender: false, user_gender: :male)
        }

        it { expect(result).to be_falsy }
      end
    end

    describe 'with existing smalltalk' do
      let!(:smalltalk) { create(:smalltalk) }
      let!(:user_smalltalk_3) { create(:user_smalltalk, user: create(:user, :ask_for_help)) }

      before {
        user_smalltalk_2.update(match_format: :many, smalltalk: smalltalk, member_status: :accepted)
        user_smalltalk_3.update(match_format: :many, smalltalk: smalltalk, member_status: :accepted)
        smalltalk.update(match_format: :many, number_of_people: 2)
      }

      describe 'format' do
        context 'match one with same format' do
          before { user_smalltalk_1.update(match_format: :many) }

          it { expect(result).to be_truthy }
        end

        context 'match none with different format' do
          before { user_smalltalk_1.update(match_format: :one) }

          it { expect(result).to be_falsy }
        end
      end
    end
  end
end
