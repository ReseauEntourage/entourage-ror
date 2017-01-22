require 'rails_helper'

RSpec.describe Atd::CsvImporter do
  
  describe 'match' do
    let!(:user1) { FactoryGirl.create(:public_user, email: "foo@bar.com") }
    let!(:user2) { FactoryGirl.create(:public_user, email: "foo1@bar.com") }
    let!(:user3) { FactoryGirl.create(:public_user, phone: "+33612345679") }
    let!(:user4) { FactoryGirl.create(:public_user) }

    let(:csv) { File.read("spec/fixtures/atd.csv") }
    subject { Atd::CsvImporter.new(csv: csv) }
    it { expect(subject.match.detect{|r| r[:atd_id]=="2345"}[:entourage_id]).to eq(user1.id) }
    it { expect(subject.match.detect{|r| r[:atd_id]=="1234"}[:entourage_id]).to eq(user2.id) }
    it { expect(subject.match.detect{|r| r[:atd_id]=="7543"}[:entourage_id]).to eq(user3.id) }
  end
end