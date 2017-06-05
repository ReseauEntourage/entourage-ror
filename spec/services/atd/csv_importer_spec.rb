require 'rails_helper'

RSpec.describe Atd::CsvImporter do
  
  describe 'match' do
    let!(:user1) { FactoryGirl.create(:public_user, email: "foo@bar.com", created_at: Date.parse(Atd::CsvImporter::ATD_COMMUNICATION_DATE)-1.day) }
    let!(:user2) { FactoryGirl.create(:public_user, email: "foo1@bar.com", created_at: Date.parse(Atd::CsvImporter::ATD_COMMUNICATION_DATE)+1.day) }
    let!(:user3) { FactoryGirl.create(:public_user, phone: "+33612345679", created_at: Date.parse(Atd::CsvImporter::ATD_COMMUNICATION_DATE)+31.day) }
    let!(:user4) { FactoryGirl.create(:pro_user, phone: "+33612345675") }
    let!(:user5) { FactoryGirl.create(:public_user) }
    let!(:partner) { FactoryGirl.create(:partner) }

    let(:csv) { File.read("spec/fixtures/atd/atd_entourage_20170410_complet.csv") }
    subject { Atd::CsvImporter.new(csv: csv).match }

    # def find_with_atd_id(atd_id)
    #   CSV.read(subject, headers: true).detect{|r| r[0]==atd_id}
    # end
    #
    # describe "match email and phone" do
    #   it { expect(find_with_atd_id("1910")[1].to_i).to eq(user1.id) }
    #   it { expect(find_with_atd_id("5530")[1].to_i).to eq(user2.id) }
    #   it { expect(find_with_atd_id("10148384")[1].to_i).to eq(user3.id) }
    # end

    # describe "ATD status" do
    #   it { expect(find_with_atd_id("2345")[4]).to eq("BEFORE_COMMUNICATION") }
    #   it { expect(find_with_atd_id("1234")[4]).to eq("DURING_COMMUNICATION") }
    #   it { expect(find_with_atd_id("7543")[4]).to eq("AFTER_COMMUNICATION") }
    #   it { expect(find_with_atd_id("3459")[4]).to eq("PRO") }
    # end

    describe "create atd_users" do
      before { Atd::CsvImporter.new(csv: csv).match }
      it { expect(AtdUser.count).to eq(3) }
      it { expect(AtdUser.first.atd_id).to eq(1910) }
      it { expect(AtdUser.first.mail_hash).to eq("823776525776c8f23a87176c59d25759da7a52c4") }
      it { expect(AtdUser.first.tel_hash).to eq("") }
    end

    describe "create user partner for mathcing users" do
      before { Atd::CsvImporter.new(csv: csv).match }
      it { expect(UserPartner.count).to eq(3) }
      it { expect(UserPartner.all.map(&:user_id)).to match_array([user1.id, user2.id, user3.id]) }
    end
  end
end
