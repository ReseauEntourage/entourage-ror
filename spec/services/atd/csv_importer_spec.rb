require 'rails_helper'

RSpec.describe Atd::CsvImporter do

  describe 'match' do

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

    context "Code action 'created'" do
      let!(:user1) { FactoryGirl.create(:public_user, email: "foo@bar.com", created_at: Date.parse(Atd::CsvImporter::ATD_COMMUNICATION_DATE)-1.day) }
      let!(:user2) { FactoryGirl.create(:public_user, email: "foo1@bar.com", created_at: Date.parse(Atd::CsvImporter::ATD_COMMUNICATION_DATE)+1.day) }
      let!(:user3) { FactoryGirl.create(:public_user, phone: "+33612345679", created_at: Date.parse(Atd::CsvImporter::ATD_COMMUNICATION_DATE)+31.day) }
      let!(:user4) { FactoryGirl.create(:pro_user, phone: "+33612345675") }
      let!(:user5) { FactoryGirl.create(:public_user) }
      let!(:partner) { FactoryGirl.create(:partner) }

      describe "create atd_users" do
        before { Atd::CsvImporter.new(csv: csv).match }
        it { expect(AtdUser.count).to eq(5) }
        it { expect(AtdUser.first.atd_id).to eq(1910) }
        it { expect(AtdUser.first.mail_hash).to eq("823776525776c8f23a87176c59d25759da7a52c4") }
        it { expect(AtdUser.first.tel_hash).to eq("") }
      end

      describe "set atd_friend flagsfor mathcing users" do
        before { Atd::CsvImporter.new(csv: csv).match }
        it { expect(User.atd_friends).to match_array([user1, user2, user3]) }
      end
    end

    context "code action 'modified'" do
      let!(:user6) { FactoryGirl.create(:public_user, email: "foo2@bar.com")  }
      let!(:matched_atd_user) { FactoryGirl.create(:atd_user, user: user6, atd_id: 1014, mail_hash: "foobar") }

      let!(:user7) { FactoryGirl.create(:public_user, email: "foo3@bar.com")  }
      let!(:unmatched_atd_user) { FactoryGirl.create(:atd_user, atd_id: 5678, mail_hash: "foobar") }

      before { Atd::CsvImporter.new(csv: csv).match }
      it { expect(matched_atd_user.reload.mail_hash).to eq("f2fd6bd59f5c2f3cb04c90b432721715a4ecc204") }
      it { expect(unmatched_atd_user.reload.user).to eq(user7) }
    end
  end
end
