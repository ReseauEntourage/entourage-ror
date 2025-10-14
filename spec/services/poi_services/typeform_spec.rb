require 'rails_helper'

describe PoiServices::Typeform do
  describe 'key_from_title' do
    let(:subject) { PoiServices::Typeform.key_from_title(title) }

    describe 'success' do
      context 'existing key name' do
        let(:title) { 'Téléphone de la structure' }

        it { expect(subject).to eq(:phone) }
      end

      context 'non case sensitive' do
        let(:title) { 'téléphone de la structure' }

        it { expect(subject).to eq(:phone) }
      end

      context 'non accent sensitive' do
        let(:title) { 'telephone de la structure' }

        it { expect(subject).to eq(:phone) }
      end

      context 'another existing key name' do
        let(:title) { 'Site Internet de la structure' }

        it { expect(subject).to eq(:website) }
      end
    end

    describe 'failure' do
      context 'non existing key name' do
        let(:title) { 'Titre quelconque' }

        it { expect(subject).to eq(nil) }
      end
    end
  end

  describe 'convert_params' do
    let(:subject) { PoiServices::Typeform.convert_params(params) }
    let(:params) { {
      'definition' => {
        'id' => 'h4PDuZ',
        'title' => 'Appli - Ajoutez une structure au Guide de solidarité',
        'fields' => [
          {
            'id' => id_1,
            'ref' => 'abcde-fghij',
            'type' => 'short_text',
            'title' => 'Nom de la structure',
            'properties' => {}
          }
        ]
      },
      'answers' => [
        {
          'type' => 'text',
          'text' => 'Lorem ipsum dolor',
          'field' => {
            'id' => id_2,
            'type' => 'short_text',
            'ref' => 'abcde-fghij'
          }
        }
      ]
    }}

    context 'identical id' do
      let(:id_1) { 'CECtygYZI3oh' }
      let(:id_2) { 'CECtygYZI3oh' }

      it { expect(subject).to eq({ name: 'Lorem ipsum dolor' }) }
    end

    context 'different id' do
      let(:id_1) { 'CECtygYZI3oh' }
      let(:id_2) { 'kp1TRuiByCPM' }

      it { expect(subject).to eq({}) }
    end
  end
end
