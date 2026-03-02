require 'rails_helper'

describe SalesforceServices::JoinRequest do
  describe "initialize" do
    let(:join_request) { create(:join_request, joinable: joinable) }
    let(:subject) { SalesforceServices::JoinRequest.new(join_request) }

    context "outing" do
      let(:joinable) { create(:outing) }

      it { expect { subject }.not_to raise_error }
    end

    context "neighborhood" do
      let(:joinable) { create(:neighborhood) }

      it { expect { subject }.to raise_error(ArgumentError) }
    end
  end

  describe "is_synchable?" do
    let(:outing) { create(:outing, :outing_class) }
    let(:join_request) { create(:join_request, joinable: outing) }
    let(:subject) { SalesforceServices::JoinRequest.new(join_request).is_synchable? }

    context "outing is synchable" do
      before { SalesforceServices::Outing.any_instance.stub(:is_synchable?) { true } }

      it { expect(subject).to be(true) }
    end

    context "outing is not synchable" do
      before { SalesforceServices::Outing.any_instance.stub(:is_synchable?) { false } }

      it { expect(subject).to be(false) }
    end
  end

  describe "upsert" do
    let(:outing) { create(:outing) }
    let(:join_request) { create(:join_request, joinable: outing) }
    let(:subject) { SalesforceServices::JoinRequest.new(join_request) }

    before {
      SalesforceServices::Contact.any_instance.stub(:find_id) { 'sf_contact_id' }
      SalesforceServices::Outing.any_instance.stub(:find_id) { 'sf_campaign_id' }
    }

    it "calls upsert! on client" do
      expect_any_instance_of(Restforce::Client).to receive(:upsert!).with(
        "CampaignMember", "JoinRequestId__c", hash_including(JoinRequestId__c: join_request.id)
      )
      subject.upsert
    end

    context "when duplicate error occurs" do
      before {
        expect_any_instance_of(Restforce::Client).to receive(:upsert!).and_raise(Restforce::ErrorCode::DuplicateValue.new("Déjà membre de campagne.", "DUPLICATE_VALUE"))
      }

      it "falls back to update after finding id" do
        expect_any_instance_of(Restforce::Client).to receive(:query).with(
          "select Id from CampaignMember where JoinRequestId__c = '#{join_request.id}'"
        ).and_return([])

        expect_any_instance_of(Restforce::Client).to receive(:query).with(
          "select Id from CampaignMember where ContactId = 'sf_contact_id' and CampaignId = 'sf_campaign_id'"
        ).and_return([OpenStruct.new(Id: 'sf_campaign_member_id')])

        expect_any_instance_of(Restforce::Client).to receive(:update).with(
          "CampaignMember", hash_including(Id: 'sf_campaign_member_id')
        )

        subject.upsert
      end
    end
  end
end
