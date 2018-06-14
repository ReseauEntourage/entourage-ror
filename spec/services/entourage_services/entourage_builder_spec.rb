require 'rails_helper'

describe EntourageServices::EntourageBuilder do

  describe '.update' do
    describe "don't touch updated_at when closing" do
      let(:entourage) { FactoryGirl.create(:entourage, updated_at: 10.hours.ago) }
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
end
