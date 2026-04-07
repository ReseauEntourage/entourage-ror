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
end
