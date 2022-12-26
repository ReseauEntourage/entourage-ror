require 'rails_helper'

describe PoiServices::Soliguide do
  describe 'create_all' do
    let!(:category_6) { create(:category, name: 'foo', id: 6) }
    let!(:category_7) { create(:category, name: 'bar', id: 7) }

    let(:poi_struct) { {
      uuid: "s17205",
      source_id: 17205,
      source: :soliguide,
      source_url: "https://soliguide.fr/fiche/association-nour-paris-17205",
      name: "Association Nour - Faustine Caron",
      description: "Nour est une association loi 1901 créée en 2019 qui vise l'inclusion sociale par le yoga.Nour est née d'une volonté de rendre les pratiques douces telles que le yoga accessibles à tous et d'en faire un vecteur de lien social.Nous animons des cours et ateliers yoga dans les centres sociaux, au sein de structures associatives et dans les établissements de santé, auprès des personnes en situation d'Exil et / ou de précarité.",
      longitude: 2.353211,
      latitude: 48.869251,
      address: "15 Bis Boulevard St Denis, 75002 Paris",
      phone: "06 95 79 07 75",
      phones: "06 95 79 07 75",
      website: "https://nour-yoga.com/",
      email: "contact@nour-yoga.com",
      audience: "Accueil inconditionnel\n" +
        "Sur inscription (L'inscription en ligne : https://nour-yoga.com/reserver-un-cours/)\n" +
        "Animaux non autorisés\n" +
        "Autres précisions : <p>Si vous rencontrez des problèmes avec l'inscription, contactez :&nbsp;</p><p><a href=\"mailto:contact@nour-yoga.com\">contact@nour-yoga.com</a></p><p>Siobhan : 0760892704</p>",
      category_ids: [6, 7],
      source_category_id: 801,
      source_category_ids: [801],
      hours: " : Fermé\n" +
        "Ven : 10h00 à 20h00\n" +
        "Lun : 10h00 à 20h00\n" +
        "Sam : Fermé\n" +
        "Dim : Fermé\n" +
        "Jeu : 10h00 à 20h00\n" +
        "Mar : Fermé\n" +
        "Mer : 10h00 à 20h00",
      languages: ""
    } }

    let(:poi_0) { poi_struct.merge({ uuid: "s0", source_id: 0 }) }
    let(:poi_1) { poi_struct.merge({ uuid: "s1", source_id: 1 }) }
    let(:poi_2) { poi_struct.merge({ uuid: "s2", source_id: 2 }) }
    let(:poi_3) { poi_struct.merge({ uuid: "s3", source_id: 3 }) }

    subject { PoiServices::SoliguideImporter.new.create_all }

    context "2 results, batch by 1" do
      before {
        PoiServices::SoliguideIndex::BATCH_LIMIT = 1

        PoiServices::SoliguideImporter.any_instance.stub(:nb_results) { 2 }

        PoiServices::SoliguideIndex.stub(:post_all_for_page).with(1, :long) { [poi_0] }
        PoiServices::SoliguideIndex.stub(:post_all_for_page).with(2, :long) { [poi_1 ]}
      }

      it { expect { subject }.to change { Poi.count }.by(2) }
    end

    context "4 results, batch by 2" do
      before {
        PoiServices::SoliguideIndex::BATCH_LIMIT = 2
        PoiServices::SoliguideImporter.any_instance.stub(:nb_results) { 4 }

        PoiServices::SoliguideIndex.stub(:post_all_for_page).with(1, :long) { [poi_0, poi_1] }
        PoiServices::SoliguideIndex.stub(:post_all_for_page).with(2, :long) { [poi_2, poi_3] }
      }

      it { expect { subject }.to change { Poi.count }.by(4) }
    end

    context "checking content on real example (adding category 7)" do
      let(:poi_0) { poi_struct.merge({ uuid: "s17205", source_id: 17205 }) }

      before {
        PoiServices::SoliguideIndex::BATCH_LIMIT = 1

        PoiServices::SoliguideImporter.any_instance.stub(:nb_results) { 1 }

        PoiServices::SoliguideIndex.stub(:post_all_for_page).with(1, :long) { [poi_0] }
      }

      before { subject }

      it { expect(Poi.count).to eq(1) }
      it { expect(Poi.first.attributes.except("id", "created_at", "updated_at")).to eq({
        "name" => "Association Nour - Faustine Caron",
        "description" => "Nour est une association loi 1901 créée en 2019 qui vise l'inclusion sociale par le yoga.Nour est née d'une volonté de rendre les pratiques douces telles que le yoga accessibles à tous et d'en faire un vecteur de lien social.Nous animons des cours et ateliers yoga dans les centres sociaux, au sein de structures associatives et dans les établissements de santé, auprès des personnes en situation d'Exil et / ou de précarité.",
        "latitude" => 48.869251,
        "longitude" => 2.353211,
        "adress" => "15 Bis Boulevard St Denis, 75002 Paris",
        "phone" => "06 95 79 07 75",
        "website" => "https://nour-yoga.com/",
        "email" => "contact@nour-yoga.com",
        "audience" => "Accueil inconditionnel\nSur inscription (L'inscription en ligne : https://nour-yoga.com/reserver-un-cours/)\nAnimaux non autorisés\nAutres précisions : <p>Si vous rencontrez des problèmes avec l'inscription, contactez :&nbsp;</p><p><a href=\"mailto:contact@nour-yoga.com\">contact@nour-yoga.com</a></p><p>Siobhan : 0760892704</p>",
        "category_id" => 6,
        "validated" => true,
        "partner_id" => nil,
        "textsearch" => nil,
        "source" => "soliguide",
        "source_id" => 17205,
        "hours" => " : Fermé\nVen : 10h00 à 20h00\nLun : 10h00 à 20h00\nSam : Fermé\nDim : Fermé\nJeu : 10h00 à 20h00\nMar : Fermé\nMer : 10h00 à 20h00",
        "languages" => ""
      }) }
      it { expect(Poi.first.category_ids).to eq([6, 7]) }
    end
  end
end
