require 'rails_helper'

describe PoiServices::SoliguideShow do
  describe "show" do
    let(:subject) { PoiServices::SoliguideShow.get(1) }

    let(:response_body) { File.read(Rails.root.join('spec/fixtures/soliguide_show_1.body')) }
    let(:response_stub) { instance_double('Net::HTTPResponse', body: response_body) }

    before { allow(PoiServices::SoliguideShow).to receive(:query).and_return(response_stub) }

    # expected result is:
    # {
    #   :uuid => "s1",
    #   :source_id => 1,
    #   :source => :soliguide,
    #   :source_url => "https://soliguide.fr/fiche/paj-permanence-accueil-jeunes-paris-1",
    #   :name => "PAJ (Permanence Accueil Jeunes)",
    #   :description => "La PAJ est un accueil de jour qui s’adresse à des jeunes hommes et jeunes femmes en situation d’errance sur le territoire parisien. Ce lieu d’écoute a pour objectif d’aider les jeunes à nouer des liens sociaux et de leur permettre d’accéder aux dispositifs de droit commun.Les équipes de la PAJ proposent un temps de pause et d’écoute afin:de permettre à chaque jeune de connaître ses ressources personnellesde ralentir le processus d’errance, d’offrir la possibilité de « rebondir »de rendre alors possible l’accès aux structures d’aide et au dispositif de droit commun",
    #   :longitude => 2.379976,
    #   :latitude => 48.871202,
    #   :address => "24 Rue Ramponeau, 75020 Paris",
    #   :postal_code => "75020",
    #   :phone => "0148050101",
    #   :phones => "0148050101",
    #   :website => "https://anrs.asso.fr/etablissements-services/insertion/permanence-accueil-ecoute-jeunes-paej/",
    #   :email => "paj@anrs.asso.fr",
    #   :audience => "Accueil préférentiel : de 12 à 25 ans, victime de violence, en situation d'addiction, en situation de handicap, porteuse du VIH, travailleur(euse) du sexe, sortant de prison, étudiant(e)\nAccueil sans rendez-vous",
    #   :category_ids => [5, 1, 42, 43, 63, 40],
    #   :source_category => "day_hosting",
    #   :source_categories => ["day_hosting", "seated_catering", "shower", "laundry", "luggage_storage", "toilets", "electrical_outlets_available"],
    #   :hours => "lun : 9h30 à 16h00\nmar : 9h30 à 16h00\nmer : 9h30 à 13h30\njeu : 9h30 à 12h30\nven : 9h30 à 16h00\nsam : Fermé\ndim : Fermé",
    #   :languages => "Français"
    # }

    it { expect(subject).to have_key(:uuid) }
    it { expect(subject[:uuid]).to eq("s1") }

    it { expect(subject).to have_key(:source_id) }
    it { expect(subject[:source_id]).to eq(1) }

    it { expect(subject).to have_key(:source) }
    it { expect(subject[:source]).to eq(:soliguide) }

    it { expect(subject).to have_key(:source_url) }
    it { expect(subject[:source_url]).to match(/soliguide.fr/) }

    it { expect(subject).to have_key(:name) }
    it { expect(subject[:name]).to match(/PAJ/) }

    it { expect(subject).to have_key(:description) }
    it { expect(subject[:description]).to match(/PAJ/) }

    it { expect(subject).to have_key(:longitude) }
    it { expect(subject[:longitude].to_i).to eq(2) }

    it { expect(subject).to have_key(:latitude) }
    it { expect(subject[:latitude].to_i).to eq(48) }

    it { expect(subject).to have_key(:address) }
    it { expect(subject[:address]).to match(/Paris/) }

    it { expect(subject).to have_key(:postal_code) }
    it { expect(subject[:postal_code]).to match(/75/) }

    it { expect(subject).to have_key(:phone) }
    it { expect(subject[:phone]).to match(/01/) }

    it { expect(subject).to have_key(:phones) }
    it { expect(subject[:phones]).to match(/01/) }

    it { expect(subject).to have_key(:website) }
    it { expect(subject[:website]).to match(/http/) }

    it { expect(subject).to have_key(:email) }
    it { expect(subject[:email]).to match(/@/) }

    it { expect(subject).to have_key(:audience) }
    it { expect(subject[:audience]).to match(/Accueil/) }

    it { expect(subject).to have_key(:category_ids) }
    it { expect(subject[:category_ids]).to include(5) }

    it { expect(subject).to have_key(:source_category) }
    it { expect(subject[:source_category]).to eq("day_hosting") }

    it { expect(subject).to have_key(:source_categories) }
    it { expect(subject[:source_categories]).to eq(["day_hosting", "seated_catering", "shower", "laundry", "luggage_storage", "toilets", "electrical_outlets_available"]) }

    it { expect(subject).to have_key(:hours) }
    it { expect(subject[:hours]).to match(/lun/) }

    it { expect(subject).to have_key(:languages) }
    it { expect(subject[:languages]).to match(/Fr/) }
  end
end
