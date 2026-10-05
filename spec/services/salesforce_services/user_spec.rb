require 'rails_helper'

describe SalesforceServices::User do
  describe '#upsert' do
    let(:user) { create :user }
    let(:service) { described_class.new(user) }

    before do
      SalesforceServices::Lead.any_instance.stub(:find_id) { lead_id }
      SalesforceServices::Contact.any_instance.stub(:find_id) { 'existing-contact-id' }
      SalesforceServices::Contact.any_instance.stub(:upsert) { 'created-contact-id' }
      SalesforceServices::Contact.any_instance.stub(:update) { true }
      service.stub(:upsert_from_fields) { |fields| fields }
    end

    subject { service.upsert }

    context 'with a lead' do
      let(:lead_id) { 'lead-id' }

      it { expect(subject['Prospect__c']).to eq('lead-id') }
      it { expect(subject['Contact__c']).to eq('existing-contact-id') }
    end

    context 'without lead' do
      let(:lead_id) { nil }

      it { expect(subject['Prospect__c']).to be_nil }
      it { expect(subject['Contact__c']).to eq('created-contact-id') }
    end
  end
end
