require 'rails_helper'

describe Translatable do
  describe "translate_field!" do
    let(:subject) { record.translate_field!(translation, field) }
    let(:translation) { Translation.find_or_initialize_by(instance: record) }

    before {
      Translation::LANGUAGES.each do |lang|
        [Neighborhood, Entourage, ChatMessage].each do |klass|
          klass.any_instance.stub(:text_translation).with("Foo", lang) { "Foo+#{lang}" }
          klass.any_instance.stub(:text_translation).with("Bar", lang) { "Bar+#{lang}" }
        end
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

        before { subject }

        it { expect(translation).to be_a(Translation) }
        it { expect(translation.fr.name).to eq("Foo+fr") }
        it { expect(translation.en.name).to eq("Foo+en") }
        it { expect(translation.instance_type).to eq("Neighborhood") }
      end
    end

    context "outing" do
      let(:record) { create(:outing, title: "Foo", description: "Bar") }

      context "translations with correct translation_key" do
        let(:field) { :title }

        before { subject }

        it { expect(translation).to be_a(Translation) }
        it { expect(translation.fr.title).to eq("Foo+fr") }
        it { expect(translation.en.title).to eq("Foo+en") }
        it { expect(translation.instance_type).to eq("Entourage") }
      end
    end

    context "chat_message" do
      let(:record) { create(:chat_message, content: "Foo") }

      context "translations with correct translation_key" do
        let(:field) { :content }

        before { subject }

        it { expect(translation).to be_a(Translation) }
        it { expect(translation.fr.content).to eq("Foo+fr") }
        it { expect(translation.en.content).to eq("Foo+en") }
        it { expect(translation.instance_type).to eq("ChatMessage") }
      end
    end
  end

  describe "text_translation" do
    before {
      User.any_instance.stub(:lang) { :fr }

      stub_request(:get, "https://translate.google.com/m?q=Foofr&sl=fr&tl=en").to_return(body: '<div class="result-container">Fooen</div>')
    }

    let(:subject) { record.text_translation("Foofr", :en) }
    let(:record) { create(:neighborhood, name: "Foo", description: "Bar") }

    it { expect(subject).to eq("Fooen") }
  end
end
