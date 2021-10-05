require 'rails_helper'

describe EntourageServices::EntourageBuilder do

  describe '.update' do
    describe "don't touch updated_at when closing" do
      let(:entourage) { FactoryBot.create(:entourage, updated_at: 10.hours.ago) }
      subject { -> { described_class.update(entourage: entourage, params: params) } }

      context 'the status changed to closed' do
        let(:params) { { status: 'closed' } }
        it { should_not change { entourage.reload.updated_at } }
      end

      context 'the status changed to something else' do
        let(:params) { { status: 'blacklisted' } }
        it { should change { entourage.reload.updated_at } }
      end

      context 'the status changed to close but another attribute changed' do
        let(:params) { { status: 'closed', title: 'new title' } }
        it { should change { entourage.reload.updated_at } }
      end
    end
  end

  describe '#create' do
    let(:user) { create :public_user }
    let(:params) { {title: "Foo", entourage_type: :contribution, location: {latitude: 1, longitude: 2}} }
    let(:service) { EntourageServices::EntourageBuilder.new(params: params, user: user) }

    it { expect(service.create).to be_persisted }
    it { expect(service.create.attributes.symbolize_keys).to include(
      title: "Foo",
      entourage_type: 'contribution',
      latitude: 1,
      longitude: 2
    ) }

    it "EntourageServices::NeighborhoodAnnouncement.on_create" do
      expect(EntourageServices::NeighborhoodAnnouncement).to receive(:on_create)
      entourage = service.create
    end

    it "FollowingService.on_create_entourage" do
      expect(FollowingService).to receive(:on_create_entourage)
      entourage = service.create
    end
  end

  describe 'cancel' do
    describe 'actions are not eligible to cancellation' do
      let(:action) { FactoryBot.create(:entourage) }
      let(:params) { { cancellation_message: 'my message' } }
      subject { -> { described_class.cancel(entourage: action, params: params) } }

      it { should_not change { action.reload.status } }
      it { should_not change { ChatMessage.count } }
    end

    describe 'outings are eligible to cancellation' do
      let(:outing) { FactoryBot.create(:outing) }
      let(:params) { { cancellation_message: 'my message' } }
      subject { -> { described_class.cancel(entourage: outing, params: params) } }

      it { should change { outing.reload.status } }
      it { should change { ChatMessage.count }.by(1) }
    end
  end
end
