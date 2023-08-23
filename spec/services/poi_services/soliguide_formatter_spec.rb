require 'rails_helper'

describe PoiServices::Soliguide do
  describe 'format' do
    subject { PoiServices::SoliguideFormatter.format poi }

    context 'empty poi' do
      let(:poi) {}
      it { expect(subject).to eq(nil) }
    end

    context 'minimum information' do
      let(:poi) { {
        'lieu_id' => 123,
        'entity' => { 'name' => 'foo' },
        'position' => {
          'location' => { 'coordinates' => [1, 2] },
          'codePostal' => '75001'
        },
        'languages' => ['en'],
        'services_all' => [{
          'name' => 'bar',
        }]
      } }

      it { expect(subject).to eq({
        uuid: "s123",
        source: :soliguide,
        source_id: 123,
        source_url: "https://soliguide.fr/fiche/",
        name: "foo",
        description: "",
        longitude: 1,
        latitude: 2,
        address: nil,
        postal_code: '75001',
        phone: nil,
        phones: "",
        website: nil,
        email: nil,
        audience: "",
        category_ids: [],
        source_category_id: nil,
        source_category_ids: [],
        hours: [],
        languages: "Anglais (English)"
      }) }
    end

    describe 'with phones' do
      let(:poi) { {
        'lieu_id' => 123,
        'entity' => { 'name' => 'foo', 'phones' => [
          { 'label' => 'phone1', 'phoneNumber' => '0601020304' },
          { 'label' => 'phone2', 'phoneNumber' => '0712345678' },
        ] },
        'position' => { 'location' => { 'coordinates' => [1, 2] } },
        'languages' => ['en'],
        'services_all' => [{
          'name' => 'bar',
        }]
      } }

      it { expect(subject).to have_key(:phone) }
      it { expect(subject[:phone]).to eq('0601020304') }
      it { expect(subject).to have_key(:phones) }
      it { expect(subject[:phones]).to eq('0601020304, 0712345678') }
    end
  end

  describe 'format_short' do
    subject { PoiServices::SoliguideFormatter.format_short poi }

    let(:poi) { {
      'lieu_id' => 123,
      'entity' => { 'name' => 'foo' },
      'position' => {
        'location' => { 'coordinates' => [1, 2] },
        'codePostal' => '75001'
      },
      'languages' => ['en'],
      'services_all' => [{
        'name' => 'bar',
      }]
    } }

    it { expect(subject).to eq({
      uuid: "s123",
      source_id: 123,
      name: "foo",
      longitude: 1,
      latitude: 2,
      address: nil,
      postal_code: "75001",
      phone: nil,
      category_id: 0,
      partner_id: nil
    }) }
  end

  describe 'format_audience' do
    subject { PoiServices::SoliguideFormatter.format_audience publics, modalities }

    let(:publics) { {
      'age' => { 'min' => 16, 'max' => 35 },
      'accueil' => 1,
      'description' => 'foo',
      'administrative' => ['refugee']
    } }

    let(:modalities) { {
      'inconditionnel' => false,
      'inscription' => {
        'checked' => true,
        'precisions' => 'bar'
      },
      'other' => 'foo'
    }}

    it { expect(subject).to eq("Accueil préférentiel : de 16 à 35 ans\nAccueil : personnes réfugiés\nAutres informations importantes : foo\nSur inscription (bar)\nAutres précisions : foo") }
  end

  describe 'format_category_ids' do
    subject { PoiServices::SoliguideFormatter.format_category_ids poi }

    context 'no services_all' do
      let(:poi) { {} }
      it { expect(subject).to eq([]) }
    end

    context 'empty services_all' do
      let(:poi) { { 'services_all' => [] } }
      it { expect(subject).to eq([]) }
    end

    context 'wrong categorie' do
      let(:poi) { { 'services_all' => [
        { 'categorie' => 1 }
      ] } }
      it { expect(subject).to eq([]) }
    end

    context 'soliguide categorie' do
      let(:poi) { { 'services_all' => [
        { 'categorie' => 100 }
      ] } }
      it { expect(subject).to eq([3]) }
    end

    context 'multiple soliguide categorie' do
      let(:poi) { { 'services_all' => [
        { 'categorie' => 100 },
        { 'categorie' => 101 },
        { 'categorie' => 203 },
        { 'categorie' => 303 },
        { 'categorie' => 304 },
      ] } }
      it { expect(subject).to eq([3, 7, 6, 40]) }
    end

    context 'multiple soliguide categorie with other categories' do
      let(:poi) { { 'services_all' => [
        { 'categorie' => 204 },
        { 'categorie' => 704 },
        { 'categorie' => 1302 },
        { 'categorie' => 1303 },
        { 'categorie' => 1305 },
      ] } }
      it { expect(subject).to match_array([7, 6, 2]) }
    end
  end

  describe 'format_publics' do
    subject { PoiServices::SoliguideFormatter.format_publics publics }

    context 'with description' do
      let(:publics) { {
        'age' => { 'min' => 16, 'max' => 35 },
        'accueil' => 1,
        'description' => 'foo',
        'administrative' => ['refugee']
      } }
      it { expect(subject).to eq(["Accueil préférentiel : de 16 à 35 ans", "Accueil : personnes réfugiés", "Autres informations importantes : foo"]) }
    end

    context 'without description' do
      let(:publics) { {
        'age' => { 'min' => 16, 'max' => 35 },
        'accueil' => 1,
        'description' => nil,
        'administrative' => ['refugee']
      } }
      it { expect(subject).to eq(["Accueil préférentiel : de 16 à 35 ans", "Accueil : personnes réfugiés"]) }
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
      it { expect(subject).to eq([]) }
    end

    context 'all ages' do
      let(:age) {{ 'min' => 0, 'max' => 99 }}
      it { expect(subject).to eq([]) }
    end

    context 'with age' do
      let(:age) {{ 'min' => 18, 'max' => 99 }}
      it { expect(subject).to eq(['adultes uniquement']) }
    end

    context 'specific age' do
      let(:age) {{ 'min' => 8, 'max' => 39 }}
      it { expect(subject).to eq(['de 8 à 39 ans']) }
    end

    context 'min age' do
      let(:age) {{ 'min' => 8, 'max' => nil }}
      it { expect(subject).to eq(['dès 8 ans']) }
    end

    context 'max age' do
      let(:age) {{ 'min' => nil, 'max' => 18 }}
      it { expect(subject).to eq(['mineurs (-18 ans)']) }
    end
  end

  describe 'format_familialle' do
    subject { PoiServices::SoliguideFormatter.format_familialle familialle }

    context 'no familialle' do
      let(:familialle) { nil }
      it { expect(subject).to eq([]) }
    end

    context 'all familialles' do
      let(:familialle) { ['isolated', 'family', 'couple', 'pregnant'] }
      it { expect(subject).to eq([]) }
    end

    context 'one familialle' do
      let(:familialle) { ['pregnant'] }
      it { expect(subject).to eq(['Femme enceinte']) }
    end

    context 'some familialles' do
      let(:familialle) { ['family', 'pregnant'] }
      it { expect(subject).to eq(['Famille', 'Femme enceinte']) }
    end
  end

  describe 'format_administrative' do
    subject { PoiServices::SoliguideFormatter.format_administrative administrative }

    context 'no format_administrative' do
      let(:administrative) { nil }
      it { expect(subject).to eq(nil) }
    end

    context 'empty format_administrative' do
      let(:administrative) { [] }
      it { expect(subject).to eq(nil) }
    end

    context 'all format_administrative' do
      let(:administrative) { ["regular", "asylum", "refugee", "undocumented"] }
      it { expect(subject).to eq(nil) }
    end

    context 'regular' do
      let(:administrative) { ["regular"] }
      it { expect(subject).to eq("personnes en situation régulière") }
    end

    context 'asylum' do
      let(:administrative) { ["asylum"] }
      it { expect(subject).to eq("personnes demandeurs d'asile") }
    end

    context 'undocumented' do
      let(:administrative) { ["undocumented"] }
      it { expect(subject).to eq("personnes sans papiers") }
    end

    context 'refugee' do
      let(:administrative) { ["refugee"] }
      it { expect(subject).to eq("personnes réfugiés") }
    end

    context 'asylum and refugee' do
      let(:administrative) { ["asylum", "refugee"] }
      it { expect(subject).to eq("personnes demandeurs d'asile, réfugiés") }
    end
  end

  describe 'format_other' do
    subject { PoiServices::SoliguideFormatter.format_other other }

    context 'no format_other' do
      let(:other) { nil }
      it { expect(subject).to eq([]) }
    end

    context 'empty format_other' do
      let(:other) { [] }
      it { expect(subject).to eq([]) }
    end

    context 'all format_other' do
      let(:other) { ['violence', 'addiction', 'handicap', 'lgbt+', 'hiv', 'prostitution', 'prison', 'student'] }
      it { expect(subject).to eq([]) }
    end

    context 'student format_other' do
      let(:other) { ['student', 'foo'] }
      it { expect(subject).to eq(["étudiant(e)"]) }
    end

    context 'some format_other' do
      let(:other) { ['violence', 'prison'] }
      it { expect(subject).to eq(["victime de violence", "sortant de prison"]) }
    end

    context 'invalid format_other' do
      let(:other) { ['foo', 'bar'] }
      it { expect(subject).to eq([]) }
    end
  end

  describe 'format_animal' do
    subject { PoiServices::SoliguideFormatter.format_animal animal }

    context 'no animal' do
      let(:animal) { nil }
      it { expect(subject).to eq(nil) }
    end

    context 'animal not authorized' do
      let(:animal) { { 'checked' => false } }
      it { expect(subject).to eq("Animaux non autorisés") }
    end

    context 'animal authorized' do
      let(:animal) { { 'checked' => true } }
      it { expect(subject).to eq("Animaux autorisés") }
    end
  end

  describe 'format_other_modalities' do
    subject { PoiServices::SoliguideFormatter.format_other_modalities other }

    context 'no other' do
      let(:other) { nil }
      it { expect(subject).to eq([]) }
    end

    context 'other not authorized' do
      let(:other) { { 'other' => nil } }
      it { expect(subject).to eq([]) }
    end

    context 'other authorized' do
      let(:other) { { 'other' => 'foo' } }
      it { expect(subject).to eq(["Autres précisions : foo"]) }
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
      it { expect(subject).to eq(["Accueil sans rendez-vous"]) }
    end

    context 'with inconditionnel and inscription' do
      let(:modalities) { {
        'inconditionnel' => true,
        'appointment' => {
          'checked' => true,
          'precisions' => 'foo'
        }
      } }
      it { expect(subject).to eq(["Accueil sans rendez-vous"]) }
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

    context 'with animal' do
      let(:modalities) { { 'animal' => { 'checked' => true } } }

      it { expect(subject).to eq(['Animaux autorisés'])}
    end

    context 'without animal' do
      let(:modalities) { { 'animal' => { 'checked' => false } } }

      it { expect(subject).to eq(['Animaux non autorisés'])}
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

    context 'on monday, tuesday' do
      let(:hours) {
        {
          "closedHolidays"=>"UNKNOWN",
          "description"=>nil,
          "friday"=> {
            "open"=>true,
            "timeslot"=>[
              { "end"=>1230, "start"=>800 },
              { "end"=>1645, "start"=>1400 }
            ]
          },
          "monday"=> {
            "open"=>true,
            "timeslot"=>[
              { "end"=>1230, "start"=>800 },
              { "end"=>1645, "start"=>1400 }
            ]
          },
          "saturday"=>{
            "open"=>false,
            "timeslot"=>[]
          },
          "sunday"=> {
            "open"=>true,
            "timeslot"=>[
              { "end"=>1230, "start"=>900 },
              { "end"=>1645, "start"=>1400 }
            ]
          },
          "thursday"=> {
            "open"=>true,
            "timeslot"=>[
              { "end"=>1230, "start"=>800 },
              { "end"=>1645, "start"=>1400 }
            ]
          },
          "tuesday"=> {
            "open"=>true,
            "timeslot"=>[
              { "end"=>1230, "start"=>800 },
              { "end"=>1645, "start"=>1400 }
            ]
          },
          "wednesday"=> {
            "open"=>true,
            "timeslot"=>[
              { "end"=>1230, "start"=>800 },
              { "end"=>1645, "start"=>1400 }
            ]
          }
        }
      }

      it { expect(subject).to eq("Lun : 8h00 à 12h30 - 14h00 à 16h45\nMar : 8h00 à 12h30 - 14h00 à 16h45\nMer : 8h00 à 12h30 - 14h00 à 16h45\nJeu : 8h00 à 12h30 - 14h00 à 16h45\nVen : 8h00 à 12h30 - 14h00 à 16h45\nSam : Fermé\nDim : 9h00 à 12h30 - 14h00 à 16h45") }
    end
  end

  describe 'format_title' do
    subject { PoiServices::SoliguideFormatter.format_title place_name, entity_name }

    context 'no names' do
      let(:place_name) { nil }
      let(:entity_name) { nil }
      it { expect(subject).to eq("") }
    end

    context 'only place_name' do
      let(:place_name) { "Lorem ipsum dolor sit amet" }
      let(:entity_name) { nil }
      it { expect(subject).to eq("Lorem ipsum dolor sit amet") }
    end

    context 'only entity_name' do
      let(:place_name) { nil }
      let(:entity_name) { "Lorem ipsum dolor sit amet" }
      it { expect(subject).to eq("Lorem ipsum dolor sit amet") }
    end

    context 'both names without similarity' do
      let(:place_name) { "Lorem ipsum dolor sit amet" }
      let(:entity_name) { "consectetur adipiscing elit" }
      it { expect(subject).to eq("Lorem ipsum dolor sit amet - consectetur adipiscing elit") }
    end

    context 'both names with high similarity' do
      let(:place_name) { "Lorem ipsum dolor sit amet" }
      let(:entity_name) { "Lorem ipsum dolor sit amet, consectetur adipiscing" }
      it { expect(subject).to eq("Lorem ipsum dolor sit amet") }
    end
  end

  describe 'format_description' do
    subject { PoiServices::SoliguideFormatter.format_description description }

    context 'no description' do
      let(:description) { nil }
      it { expect(subject).to eq("") }
    end

    context 'plaintext description' do
      let(:description) { "Lorem ipsum dolor sit amet" }
      it { expect(subject).to eq("Lorem ipsum dolor sit amet") }
    end

    context 'html description' do
      let(:description) { "<p>Lorem ipsum dolor sit amet</p>" }
      it { expect(subject).to eq("Lorem ipsum dolor sit amet") }
    end

    context 'html accent description' do
      let(:description) { "<p>Lorem to caf&#233;t&#233;ria</p>" }
      it { expect(subject).to eq("Lorem to cafétéria") }
    end
  end

  describe 'format_phones' do
    subject { PoiServices::SoliguideFormatter.format_phones phones }

    context 'no phones' do
      let(:phones) { nil }
      it { expect(subject).to eq([]) }
    end

    context 'empty phones' do
      let(:phones) { [] }
      it { expect(subject).to eq([]) }
    end

    context 'one phone' do
      let(:phones) { [
        { 'label' => 'phone1', 'phoneNumber' => '0601020304' },
      ] }
      it { expect(subject).to eq(['0601020304']) }
    end

    context 'multiple phones' do
      let(:phones) { [
        { 'label' => 'phone1', 'phoneNumber' => '0601020304' },
        { 'label' => 'phone2', 'phoneNumber' => '0712345678' },
      ] }
      it { expect(subject).to eq(['0601020304', '0712345678']) }
    end
  end

  describe 'extract_words' do
    subject { PoiServices::SoliguideFormatter.extract_words words }

    context 'nil words' do
      let(:words) { nil }
      it { expect(subject).to eq([]) }
    end

    context 'empty words' do
      let(:words) { "" }
      it { expect(subject).to eq([]) }
    end

    context 'with 3 or less words' do
      let(:words) { "Lorem ipsum dolor sit amet" }
      it { expect(subject).to eq(["lorem", "ipsum", "dolor", "amet"]) }
    end
  end

  describe 'categories_from_entourage' do
    subject { PoiServices::SoliguideFormatter.categories_from_entourage entourage_category }

    context 'no entourage_category' do
      let(:entourage_category) { nil }
      it { expect(subject).to eq(nil) }
    end

    context 'invalid entourage_category' do
      let(:entourage_category) { 0 }
      it { expect(subject).to eq(nil) }
    end

    context 'invalid entourage_category' do
      let(:entourage_category) { 1 }
      it { expect(subject).to eq([600, 601, 602, 603, 604]) }
    end
  end
end
