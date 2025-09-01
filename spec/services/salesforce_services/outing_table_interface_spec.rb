require 'rails_helper'

describe SalesforceServices::OutingTableInterface do
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
