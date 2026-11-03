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

  describe 'outings_with_meeting_link' do
    let(:event_url) { 'https://meet.google.com/abc-defg-hij' }
    let!(:outing) { create :outing, :outing_class, online: true, event_url: event_url, salesforce_id: '701AP00001VQrHeYAL' }

    subject { SalesforceTasks.outings_with_meeting_link(since: since).pluck(:id) }

    it { expect(subject).to include(outing.id) }

    context 'starting before since' do
      let(:since) { 1.week.from_now }

      it { expect(subject).not_to include(outing.id) }
    end

    context 'without salesforce_id' do
      before { outing.update_column(:salesforce_id, nil) }

      it { expect(subject).not_to include(outing.id) }
    end

    context 'without event_url' do
      before { outing.update_column(:event_url, '') }

      it { expect(subject).not_to include(outing.id) }
    end

    context 'not online' do
      before { outing.update_column(:online, false) }

      it { expect(subject).not_to include(outing.id) }
    end
  end

  describe 'backfill_meeting_links' do
    let(:salesforce_id) { '701AP00001VQrHeYAL' }
    let(:event_url) { 'https://meet.google.com/abc-defg-hij' }
    let!(:outing) { create :outing, :outing_class, online: true, event_url: event_url, salesforce_id: salesforce_id }

    let(:dry_run) { true }
    let(:field) { { 'name' => 'MeetingLink__c', 'type' => 'url', 'length' => 255, 'updateable' => true } }
    let(:campaigns) { [{ 'Id' => salesforce_id, 'MeetingLink__c' => nil }] }
    let(:client) { double(:client, describe: { 'fields' => [field] }, query: campaigns, update!: true) }

    subject { SalesforceTasks.backfill_meeting_links(since: since, dry_run: dry_run, pause: 0) }

    before { allow(SalesforceServices::Connect).to receive(:client).and_return(client) }

    context 'dry run' do
      it { expect(subject[:updated]).to eq([[outing.id, nil, event_url]]) }
      it { subject; expect(client).not_to have_received(:update!) }
    end

    context 'not dry run' do
      let(:dry_run) { false }

      it { expect(subject[:updated]).to eq([[outing.id, nil, event_url]]) }
      it { subject; expect(client).to have_received(:update!).with('Campaign', { Id: salesforce_id, 'MeetingLink__c' => event_url }) }

      it 'does not save the outing nor enqueue a job' do
        expect(SalesforceJob).not_to receive(:perform_async)
        expect { subject }.not_to(change { outing.reload.updated_at })
      end

      context 'when the update fails' do
        before { allow(client).to receive(:update!).and_raise(StandardError, 'INVALID_FIELD') }

        it { expect(subject[:errors]).to eq([[outing.id, 'INVALID_FIELD']]) }
        it { expect(subject[:updated]).to be_empty }
      end
    end

    context 'already up to date' do
      let(:dry_run) { false }
      let(:campaigns) { [{ 'Id' => salesforce_id, 'MeetingLink__c' => event_url }] }

      it { expect(subject[:up_to_date]).to eq([outing.id]) }
      it { subject; expect(client).not_to have_received(:update!) }
    end

    context 'salesforce_id stored with 15 chars' do
      let(:salesforce_id) { '701AP00001VQrHe' }
      let(:campaigns) { [{ 'Id' => '701AP00001VQrHeYAL', 'MeetingLink__c' => event_url }] }

      it { expect(subject[:up_to_date]).to eq([outing.id]) }
    end

    context 'campaign not found in salesforce' do
      let(:campaigns) { [] }

      it { expect(subject[:not_found]).to eq([outing.id]) }
    end

    context 'event_url too long for the field' do
      let(:field) { { 'name' => 'MeetingLink__c', 'type' => 'url', 'length' => 10, 'updateable' => true } }

      it { expect(subject[:too_long]).to eq([outing.id]) }
    end

    context 'without outings' do
      let(:since) { 1.week.from_now }

      it { expect(subject[:updated]).to be_empty }
      it { subject; expect(client).not_to have_received(:query) }
    end

    context 'field missing in salesforce' do
      let(:field) { { 'name' => 'Other__c' } }

      it { expect { subject }.to raise_error(/MeetingLink__c not found/) }
    end

    context 'field not updateable' do
      let(:field) { { 'name' => 'MeetingLink__c', 'updateable' => false } }

      it { expect { subject }.to raise_error(/not updateable/) }
    end
  end
end
