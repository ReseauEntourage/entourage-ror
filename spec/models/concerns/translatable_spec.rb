require 'rails_helper'

def normalize_html(html)
  Nokogiri::HTML.fragment(html).to_html
end

describe Translatable do
  describe 'translate_field!' do
    let(:subject) { record.translate! }
    let(:translation) { Translation.find_or_initialize_by(instance: record) }

    before {
      [ChatMessage, Entourage, Neighborhood].each do |klass|
        klass.any_instance.stub(:translate_field!).and_call_original
      end

      Translation::LANGUAGES.each do |lang|
        [Neighborhood, Entourage, ChatMessage].each do |klass|
          klass.any_instance.stub(:text_translation).with('Foo', lang) { "Foo+#{lang}" }
          klass.any_instance.stub(:text_translation).with('Bar', lang) { "Bar+#{lang}" }
        end
      end
    }

    after {
      [ChatMessage, Entourage, Neighborhood].each do |klass|
        klass.any_instance.stub(:translate_field!).and_return('foo')
      end
    }

    context 'neighborhood' do
      let(:record) { create(:neighborhood, name: 'Foo', description: 'Bar') }

      context 'good translation_key' do
        it { expect(subject).to eq(true) }
        it { expect { subject }.to change { Translation.count }.by(1) }
      end

      context 'translations with correct translation_key' do
        before { subject }

        it { expect(translation).to be_a(Translation) }
        it { expect(translation.fr.name).to eq('Foo') }
        it { expect(translation.en.name).to eq('Foo+en') }
        it { expect(translation.instance_type).to eq('Neighborhood') }
      end
    end

    context 'outing' do
      let(:record) { create(:outing, title: 'Foo', description: 'Bar') }

      context 'translations with correct translation_key' do
        before { subject }

        it { expect(translation).to be_a(Translation) }
        it { expect(translation.fr.title).to eq('Foo') }
        it { expect(translation.en.title).to eq('Foo+en') }
        it { expect(translation.instance_type).to eq('Entourage') }
      end
    end

    context 'chat_message' do
      let(:outing) { create(:outing, title: 'Foo', description: 'Bar') }
      let(:record) { create(:chat_message, messageable: outing, content: 'Foo') }

      context 'translations with correct translation_key' do
        before { subject }

        it { expect(translation).to be_a(Translation) }
        it { expect(translation.fr.content).to eq('Foo') }
        it { expect(translation.en.content).to eq('Foo+en') }
        it { expect(translation.instance_type).to eq('ChatMessage') }
      end
    end
  end

  describe 'text_translation' do
    before {
      User.any_instance.stub(:lang) { :fr }

      stub_request(:get, 'https://translate.google.com/m?q=Foofr&sl=fr&tl=en').to_return(body: '<div class="result-container">Fooen</div>')
    }

    let(:subject) { record.text_translation('Foofr', :en) }
    let(:record) { create(:neighborhood, name: 'Foo', description: 'Bar') }

    it { expect(subject).to eq('Fooen') }
  end

  describe 'html_translation' do
    before do
      User.any_instance.stub(:lang) { :fr }

      allow_any_instance_of(Neighborhood).to receive(:text_translation) do |_, text, _|
        case text
        when 'Bonjour, comment allez-vous ?' then 'Hello, how are you?'
        when 'ma maison' then 'my home'
        when 'Salut' then 'Hi'
        when 'Ceci est un test' then 'This is a test'
        else text
        end
      end
    end

    let(:subject) { record.html_translation(input_html, :en) }
    let(:record) { create(:neighborhood, name: 'Foo', description: 'Bar') }

    context 'traduit uniquement le texte et conserve la structure HTML' do
      let(:input_html) { '<p dir="ltr">Bonjour, comment allez-vous ?</p><a  href="https://google.com">ma maison</a>' }
      let(:expected_html) { '<p dir="ltr">Hello, how are you?</p><a  href="https://google.com">my home</a>' }

      it { expect(normalize_html(subject)).to eq(normalize_html(expected_html)) }
    end

    context 'gère les balises imbriquées' do
      let(:input_html) { '<div><p>Salut</p><span>Ceci est un test</span></div>' }
      let(:expected_html) { '<div><p>Hi</p><span>This is a test</span></div>' }

      it { expect(normalize_html(subject)).to eq(normalize_html(expected_html)) }
    end

    context 'ne modifie pas les liens et les attributs' do
      let(:input_html) { '<a href="https://google.com" title="Lien">ma maison</a>' }
      let(:expected_html) { '<a href="https://google.com" title="Lien">my home</a>' }

      it { expect(normalize_html(subject)).to eq(normalize_html(expected_html)) }
    end

    context 'gère le texte sans HTML' do
      let(:input_html) { 'Bonjour, comment allez-vous ?' }
      let(:expected_html) { 'Hello, how are you?' }

      it { expect(normalize_html(subject)).to eq(normalize_html(expected_html)) }
    end

    context 'ignore le contenu vide' do
      let(:input_html) { '<p></p><span>   </span>' }
      let(:expected_html) { '<p></p><span>   </span>' }

      it { expect(normalize_html(subject)).to eq(normalize_html(expected_html)) }
    end
  end
end
