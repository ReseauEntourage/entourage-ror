require 'rails_helper'

describe SalesforceServices::OutingTableInterface do
  let(:outing) { create :outing, :outing_class, title: title, metadata: { starts_at: starts_at, display_address: address } }

  let(:address) { '1, place du Louvre 75000 Paris' }
  let(:title) { 'Concert de musique' }
  let(:starts_at) { 1.hour.from_now }


  describe '#title' do
    subject { described_class.new(instance: outing).mapping }

    context 'when outing.city is present' do
      before { allow(subject).to receive(:truncate_priority).and_return('Paris // Concert de musique - 2025-11-05') }

      it { expect(subject.title).to eq('Paris // Concert de musique - 2025-11-05') }
    end

    context 'when outing.city is nil or blank' do
      let(:address) { nil }

      before { allow(subject).to receive(:truncate_priority).and_return('Concert de musique - 2025-11-05') }

      it { expect(subject.title).to eq('Concert de musique - 2025-11-05') }
    end
  end

  describe '#meeting_link' do
    let(:event_url) { 'https://meet.google.com/abc-defg-hij' }
    let(:outing) { create :outing, :outing_class, online: true, event_url: event_url }

    subject { described_class.new(instance: outing).mapping.meeting_link }

    it { expect(described_class::INSTANCE_MAPPING[:meeting_link]).to eq('MeetingLink__c') }

    context 'when outing is online' do
      it { expect(subject).to eq(event_url) }
    end

    context 'when outing is online without event_url' do
      let(:event_url) { '' }

      it { expect(subject).to be_nil }
    end

    context 'when outing is not online but has a legacy event_url' do
      let(:outing) { create :outing, :outing_class, online: false }

      before { outing.update_column(:event_url, event_url) }

      it { expect(subject).to be_nil }
    end
  end

  describe "truncate_priority" do
    let(:date) { "2025-08-21" }

    let(:interface) { SalesforceServices::OutingTableInterface.new(instance: create(:outing)) }
    let(:result) { interface.mapping.truncate_priority(parts, max_length: max_length, min_lengths: min_lengths) }

    context "ne tronque rien si la chaîne est déjà courte" do
      let(:parts) { ["Paris", " // ", "Concert", " - ", date] }
      let(:max_length) { 80 }
      let(:min_lengths) { [30, 4, 30, 3, date.length] }

      it { expect(result).to eq("Paris // Concert - #{date}") }
    end

    context "tronque le titre si nécessaire" do
      let(:long_title) { "Un événement exceptionnel qui dépasse largement la limite" }
      let(:parts) { ["Paris", " // ", long_title, " - ", date] }
      let(:max_length) { 60 }
      let(:min_lengths) { [20, 4, 20, 3, date.length] }

      it { expect(result.length).to be <= 50 }
      it { expect(result).to include("Paris //") }
      it { expect(result).to end_with(" - #{date}") }
      it { expect(result).to include("...") }
    end

    context "tronque la ville après le titre si nécessaire" do
      let(:long_city) {  "Une ville avec un nom incroyablement long et trop détaillé" }
      let(:long_title) { "Un événement exceptionnel qui dépasse largement la limite" }
      let(:parts) { [long_city, " // ", long_title, " - ", date] }
      let(:max_length) { 60 }
      let(:min_lengths) { [20, 4, 20, 3, date.length] }

      it { expect(result.length).to be <= 60 }
      it { expect(result).to include(" // ") }
      it { expect(result).to end_with(" - #{date}") }
      it { expect(result).to include("...") }
    end

    context "ne tronque jamais la date" do
      let(:long_title) { "Événement" * 20 }
      let(:parts) { ["Paris", " // ", long_title, " - ", date] }
      let(:max_length) { 40 }
      let(:min_lengths) { [30, 4, 30, 3, date.length] }

      it { expect(result).to end_with(date) }
      it { expect(result[-date.length..]).to eq(date) }
    end
  end

  describe "remove_emojis" do
    let(:interface) { SalesforceServices::OutingTableInterface.new(instance: create(:outing)) }
    let(:result) { interface.mapping.remove_emojis(str) }

    context "without emoji" do
      let(:str) { "titre" }

      it { expect(result).to eq("titre") }
    end

    context "with emoji" do
      let(:str) { "🏸 titre 🏸" }

      it { expect(result).to eq("titre") }
    end
  end
end
