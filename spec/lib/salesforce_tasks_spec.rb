require 'rails_helper'
require 'tasks/salesforce_tasks'

describe SalesforceTasks do
  let(:since) { 1.week.ago }
  let(:user) { create :user }
  let!(:address) { create :address, user: user }

  describe 'users_to_resync' do
    let(:after_id) { nil }

    subject { SalesforceTasks.users_to_resync(since: since, after_id: after_id).pluck(:id) }

    context 'updated since' do
      it { expect(subject).to include(user.id) }
    end

    context 'not updated since' do
      before do
        user.update_columns(updated_at: 1.month.ago, last_sign_in_at: 1.month.ago)
        address.update_columns(updated_at: 1.month.ago)
      end

      it { expect(subject).not_to include(user.id) }

      context 'but signed in since' do
        before { user.update_columns(last_sign_in_at: 1.day.ago) }

        it { expect(subject).to include(user.id) }
      end

      context 'but address updated since' do
        before { address.update_columns(updated_at: 1.day.ago) }

        it { expect(subject).to include(user.id) }
      end
    end

    context 'without address' do
      before { user.update_columns(address_id: nil) }

      it { expect(subject).not_to include(user.id) }
    end

    context 'deleted' do
      before { user.update_columns(deleted: true) }

      it { expect(subject).not_to include(user.id) }
    end

    context 'after_id' do
      context 'before user' do
        let(:after_id) { user.id - 1 }

        it { expect(subject).to include(user.id) }
      end

      context 'equal to user' do
        let(:after_id) { user.id }

        it { expect(subject).not_to include(user.id) }
      end
    end
  end

  describe 'resync_users' do
    let(:dry_run) { true }

    subject { SalesforceTasks.resync_users(since: since, dry_run: dry_run) }

    before { allow(SalesforceJob).to receive(:perform_async) }

    context 'dry run' do
      it { expect(subject).to include(user.id) }
      it { subject; expect(SalesforceJob).not_to have_received(:perform_async) }
    end

    context 'not dry run' do
      let(:dry_run) { false }

      it { expect(subject).to include(user.id) }
      it { subject; expect(SalesforceJob).to have_received(:perform_async).with('User', user.id, 'upsert') }
    end

    context 'with limit' do
      let!(:other_user) { create(:address, user: create(:user)).user }

      subject { SalesforceTasks.resync_users(since: since, limit: 1) }

      it { expect(subject.size).to eq(1) }
    end
  end
end
