require 'rails_helper'

describe PoiServices::Soliguide do
  describe 'format_audience' do
    subject { PoiServices::SoliguideFormatter.format_audience publics, modalities }

    let(:publics) { {
      'age' => { 'min' => 16, 'max' => 35 },
      'accueil' => 1,
      'description' => 'foo',
      'administrative' => ['refugee'],
      'animals' => true
    } }

    let(:modalities) { {
      'inconditionnel' => false,
      'inscription' => {
        'checked' => true,
        'precisions' => 'bar'
      }
    }}

    it { expect(subject).to eq("Accueil préférentiel : de 16 à 35 ans\nAutres informations importantes : foo\nAnimaux autorisés\nSur inscription (bar)") }
  end

  describe 'format_publics' do
    subject { PoiServices::SoliguideFormatter.format_publics publics }

    context 'with description' do
      let(:publics) { {
        'age' => { 'min' => 16, 'max' => 35 },
        'accueil' => 1,
        'description' => 'foo',
        'administrative' => ['refugee'],
        'animals' => true
      } }
      it { expect(subject).to eq(["Accueil préférentiel : de 16 à 35 ans", "Autres informations importantes : foo", "Animaux autorisés"]) }
    end

    context 'without description' do
      let(:publics) { {
        'age' => { 'min' => 16, 'max' => 35 },
        'accueil' => 1,
        'description' => nil,
        'administrative' => ['refugee'],
        'animals' => true
      } }
      it { expect(subject).to eq(["Accueil préférentiel : de 16 à 35 ans", "Autres informations importantes : personnes en situation régulière, réfugiés", "Animaux autorisés"]) }
    end
  end

  describe 'format_accueil' do
    subject { PoiServices::SoliguideFormatter.format_accueil accueil }

    context 'no accueil' do
      let(:accueil) { nil }
      it { expect(subject).to eq("inconditionnel") }
    end

    context 'accueil 0' do
      let(:accueil) { 0 }
      it { expect(subject).to eq("inconditionnel") }
    end

    context 'accueil 1' do
      let(:accueil) { 1 }
      it { expect(subject).to eq("préférentiel") }
    end

    context 'accueil 2' do
      let(:accueil) { 2 }
      it { expect(subject).to eq("exclusif") }
    end
  end

  describe 'format_age' do
    subject { PoiServices::SoliguideFormatter.format_age age }

    context 'no age' do
      let(:age) { nil }
      it { expect(subject).to eq(nil) }
    end

    context 'all ages' do
      let(:age) {{ 'min' => 0, 'max' => 99 }}
      it { expect(subject).to eq(nil) }
    end

    context 'with age' do
      let(:age) {{ 'min' => 18, 'max' => 99 }}
      it { expect(subject).to eq('adultes uniquement') }
    end

    context 'specific age' do
      let(:age) {{ 'min' => 8, 'max' => 39 }}
      it { expect(subject).to eq('de 8 à 39 ans') }
    end

    context 'min age' do
      let(:age) {{ 'min' => 8, 'max' => nil }}
      it { expect(subject).to eq('dès 8 ans') }
    end

    context 'max age' do
      let(:age) {{ 'min' => nil, 'max' => 18 }}
      it { expect(subject).to eq('mineurs (-18 ans)') }
    end
  end

  describe 'format_administrative' do
    subject { PoiServices::SoliguideFormatter.format_administrative administrative }

    context 'no format_administrative' do
      let(:administrative) { nil }
      it { expect(subject).to eq(nil) }
    end

    context 'all format_administrative' do
      let(:administrative) { ["regular", "asylum", "refugee", "undocumented"] }
      it { expect(subject).to eq(nil) }
    end

    context 'regular' do
      let(:administrative) { ["regular"] }
      it { expect(subject).to eq("personnes avec ou sans papiers") }
    end

    context 'asylum' do
      let(:administrative) { ["asylum"] }
      it { expect(subject).to eq("personnes demandeurs d'asile") }
    end

    context 'undocumented' do
      let(:administrative) { ["undocumented"] }
      it { expect(subject).to eq("personnes en situation régulière, sans papiers") }
    end

    context 'refugee' do
      let(:administrative) { ["refugee"] }
      it { expect(subject).to eq("personnes en situation régulière, réfugiés") }
    end
  end

  describe 'format_animals' do
    subject { PoiServices::SoliguideFormatter.format_animals animals }

    context 'no animals' do
      let(:animals) { nil }
      it { expect(subject).to eq(nil) }
    end

    context 'animals not authorized' do
      let(:animals) { false }
      it { expect(subject).to eq(nil) }
    end

    context 'accueil 0' do
      let(:animals) { true }
      it { expect(subject).to eq("Animaux autorisés") }
    end
  end

  describe 'format_modalities' do
    subject { PoiServices::SoliguideFormatter.format_modalities modalities }

    context 'no modalities' do
      let(:modalities) { nil }
      it { expect(subject).to eq([]) }
    end

    context 'with inconditionnel' do
      let(:modalities) { { 'inconditionnel' => true } }
      it { expect(subject).to eq(["accueil sans rendez-vous"]) }
    end

    context 'with appointment' do
      let(:modalities) { {
        'inconditionnel' => false,
        'appointment' => {
          'checked' => true,
          'precisions' => 'foo'
        }
      }}

      it { expect(subject).to eq(['Sur rendez-vous (foo)']) }
    end

    context 'with inscription' do
      let(:modalities) { {
        'inconditionnel' => false,
        'inscription' => {
          'checked' => true,
          'precisions' => 'bar'
        }
      }}

      it { expect(subject).to eq(['Sur inscription (bar)']) }
    end

    context 'with orientation' do
      let(:modalities) { {
        'inconditionnel' => false,
        'orientation' => {
          'checked' => true,
          'precisions' => 'baz'
        }
      }}

      it { expect(subject).to eq(['Sur orientation (baz)']) }
    end
  end

  describe 'format_hours' do
    subject { PoiServices::SoliguideFormatter.format_hours hours }

    context 'no hours' do
      let(:hours) { nil }
      it { expect(subject).to eq([]) }
    end

    context 'on monday, tuesday' do
      let(:hours) { {
        'monday' => {
          'open' => true,
          'timeslot' => [
            { 'start' => 800, 'end' => 1230 },
            { 'start' => 1400, 'end' => 1630 },
          ]
        },
        'tuesday' => {
          'open' => true,
          'timeslot' => [
            { 'start' => 700, 'end' => 1230 },
            { 'start' => 1330, 'end' => 1630 },
          ]
        }
      } }
      it { expect(subject).to eq("Lun : 8h00 à 12h30 - 14h00 à 16h30\nMar : 7h00 à 12h30 - 13h30 à 16h30") }
    end
  end
end
