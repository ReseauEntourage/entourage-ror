require 'rails_helper'

RSpec.describe Atd::AtdSynchronizer do

  before do
    allow_any_instance_of(Atd::CsvImporter).to receive(:match)
    allow(Atd::AtdFtp).to receive(:download_file)
  end

  describe 'synchronize' do
    context "first file to synchronize" do
      before do
        allow(Atd::AtdFtp).to receive(:list_files) { ["foobar.csv"] }
        described_class.synchronize
      end
      it { expect(AtdSynchronization.count).to eq 1 }
      it { expect(AtdSynchronization.last.filename).to eq "foobar.csv" }
    end

    context "second file to synchronize" do
      let!(:atd_synchronization) { FactoryGirl.create(:atd_synchronization, filename: "foobar.csv") }
      before do
        allow(Atd::AtdFtp).to receive(:list_files) { ["foobar.csv", "foobar2.csv"] }
        described_class.synchronize
      end
      it { expect(AtdSynchronization.count).to eq 2 }
      it { expect(AtdSynchronization.last.filename).to eq "foobar2.csv" }
    end

    context "no file to synchronize" do
      let!(:atd_synchronization) { FactoryGirl.create(:atd_synchronization, filename: "foobar.csv") }
      before do
        allow(Atd::AtdFtp).to receive(:list_files) { ["foobar.csv"] }
        described_class.synchronize
      end
      it { expect(AtdSynchronization.count).to eq 1 }
    end
  end
end
