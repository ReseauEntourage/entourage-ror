require 'rails_helper'

describe SalesforceServices::ContactTableInterface do
  let(:user) { create :user, birthdate: "1879-03-14", options: {
    gender: "female",
    discovery_source: "social",
  } }

  describe '#mapped_fields' do
    subject { described_class.new(instance: user).mapped_fields }

    it { expect(subject).to have_key("Genre__c") }
    it { expect(subject["Genre__c"]).to eq("Femme") }

    it { expect(subject).to have_key("Date_de_naissance__c") }
    it { expect(subject["Date_de_naissance__c"]).to eq("1879-03-14") }

    it { expect(subject).to have_key("Comment_nous_avez_vous_connu__c") }
    it { expect(subject["Comment_nous_avez_vous_connu__c"]).to eq("Autres réseaux (facebook, twitter, instagram...)") }
  end
end
