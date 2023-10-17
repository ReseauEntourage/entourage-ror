require 'rails_helper'

describe TranslationServices::Translator do
  describe "translate_field!" do
    let(:subject) { described_class.new(record).translate_field!(field) }

    before {
      Translation::LANGUAGES.each do |lang|
        described_class.any_instance.stub(:text_translation).with("Foo", lang) { "Foo+#{lang}" }
        described_class.any_instance.stub(:text_translation).with("Bar", lang) { "Bar+#{lang}" }
      end
    }

    context "neighborhood" do
      let(:record) { create(:neighborhood, name: "Foo", description: "Bar") }

      context "nil translation_key" do
        let(:field) { nil }

        it { expect(subject).to eq(nil) }
      end

      context "wrong translation_key" do
        let(:field) { :Bar }

        it { expect(subject).to eq(nil) }
      end

      context "good translation_key" do
        let(:field) { :name }

        it { expect(subject).to eq(true) }
        it { expect { subject }.to change { Translation.count }.by(1) }
      end

      context "translations with correct translation_key" do
        let(:field) { :name }
        let(:translation) { Translation.find_by(instance: record, instance_field: :name) }

        before { subject }

        it { expect(translation).to be_a(Translation) }
        it { expect(translation.fr).to eq("Foo+fr") }
        it { expect(translation.en).to eq("Foo+en") }
        it { expect(translation.instance_type).to eq("Neighborhood") }
      end
    end

    context "outing" do
      let(:record) { create(:outing, title: "Foo", description: "Bar") }

      context "translations with correct translation_key" do
        let(:field) { :title }
        let(:translation) { Translation.find_by(instance: record, instance_field: :title) }

        before { subject }

        it { expect(translation).to be_a(Translation) }
        it { expect(translation.fr).to eq("Foo+fr") }
        it { expect(translation.en).to eq("Foo+en") }
        it { expect(translation.instance_type).to eq("Entourage") }
      end
    end

    context "chat_message" do
      let(:record) { create(:chat_message, content: "Foo") }

      context "translations with correct translation_key" do
        let(:field) { :content }
        let(:translation) { Translation.find_by(instance: record, instance_field: :content) }

        before { subject }

        it { expect(translation).to be_a(Translation) }
        it { expect(translation.fr).to eq("Foo+fr") }
        it { expect(translation.en).to eq("Foo+en") }
        it { expect(translation.instance_type).to eq("ChatMessage") }
      end
    end
  end

  describe "text_translation" do
    before {
      User.any_instance.stub(:lang) { :fr }

      stub_request(:get, "https://translate.google.com/m?q=Foofr&sl=fr&tl=en").to_return(body: '<div class="result-container">Fooen</div>')
    }

    let(:subject) { described_class.new(record).text_translation("Foofr", :en) }
    let(:record) { create(:neighborhood, name: "Foo", description: "Bar") }

    it { expect(subject).to eq("Fooen") }
  end
end
