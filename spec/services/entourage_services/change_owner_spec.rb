require 'rails_helper'

describe EntourageServices::ChangeOwner do
  klass = EntourageServices::ChangeOwner

  let(:creator) { create(:public_user) }
  let(:member) { create(:public_user) }
  let(:other) { create(:public_user) }

  let(:entourage) { create(:entourage, user: creator, participants: [creator, member]) }
  let(:outing) { create(:outing, user: creator, participants: [creator, member]) }
  let(:neighborhood) { create(:neighborhood, user: creator, participants: [creator, member]) }

  describe 'to' do
    let(:instance) { klass.new(joinable) }
    let(:subject) { instance.to(member.id, 'foo') {} }

    context 'entourage' do
      let(:joinable) { entourage }

      context 'yield' do
        it { expect { |b| instance.to(member.id, 'foo', &b) }.to yield_with_args(false, klass::INVALID_JOINABLE) }
      end

      context 'joinable' do
        before { subject }

        it { expect(joinable.user_id).to eq(creator.id) }
      end
    end

    context 'outing' do
      let(:joinable) { outing }

      context 'yield' do
        it { expect { |b| instance.to(member.id, 'foo', &b) }.to yield_with_args(true) }
      end

      context 'joinable' do
        before { subject }

        it { expect(joinable.user_id).to eq(member.id) }
      end
    end

    context 'neighborhood' do
      let(:joinable) { neighborhood }

      context 'yield' do
        it { expect { |b| instance.to(member.id, 'foo', &b) }.to yield_with_args(true) }
      end

      context 'joinable' do
        before { subject }

        it { expect(joinable.user_id).to eq(member.id) }
      end
    end
  end
end
