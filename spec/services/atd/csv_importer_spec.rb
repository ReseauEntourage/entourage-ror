require 'rails_helper'

RSpec.describe Atd::CsvImporter do
  
  describe 'match' do
    let!(:user1) { FactoryGirl.create(:public_user, email: "foo@bar.com", created_at: Date.parse(Atd::CsvImporter::ATD_COMMUNICATION_DATE)-1.day) }
    let!(:user2) { FactoryGirl.create(:public_user, email: "foo1@bar.com", created_at: Date.parse(Atd::CsvImporter::ATD_COMMUNICATION_DATE)+1.day) }
    let!(:user3) { FactoryGirl.create(:public_user, phone: "+33612345679", created_at: Date.parse(Atd::CsvImporter::ATD_COMMUNICATION_DATE)+31.day) }
    let!(:user4) { FactoryGirl.create(:pro_user, phone: "+33612345675") }
    let!(:user5) { FactoryGirl.create(:public_user) }

    let(:csv) { File.read("spec/fixtures/atd.csv") }
    subject { Atd::CsvImporter.new(csv: csv).match }

    def find_with_atd_id(atd_id)
      CSV.read(subject, headers: true).detect{|r| r[0]==atd_id}
    end

    describe "match email and phone" do
      it { expect(find_with_atd_id("2345")[1].to_i).to eq(user1.id) }
      it { expect(find_with_atd_id("1234")[1].to_i).to eq(user2.id) }
      it { expect(find_with_atd_id("7543")[1].to_i).to eq(user3.id) }
    end

    describe "ATD status" do
      it { expect(find_with_atd_id("2345")[4]).to eq("BEFORE_COMMUNICATION") }
      it { expect(find_with_atd_id("1234")[4]).to eq("DURING_COMMUNICATION") }
      it { expect(find_with_atd_id("7543")[4]).to eq("AFTER_COMMUNICATION") }
      it { expect(find_with_atd_id("3459")[4]).to eq("PRO") }
    end
  end
end