require 'rails_helper'

describe PoiServices::Soliguide do
  describe 'create_all' do
    let!(:category) { create(:category, name: 'foo', id: 5) }
    let(:poi_struct) { {
      :uuid => "s0",
      :source_id => 0,
      :name => "La maison du partage",
      :longitude => 2.374,
      :latitude => 48.882,
      :address => "32 rue Bouret, 75019 Paris",
      :phone => nil,
      :category_id => 5,
      :partner_id => nil
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

        PoiServices::SoliguideIndex.stub(:post_all_for_page).with(1) { [poi_0] }
        PoiServices::SoliguideIndex.stub(:post_all_for_page).with(2) { [poi_1 ]}
      }

      it { expect { subject }.to change { Poi.count }.by(2) }
    end

    context "4 results, batch by 2" do
      before {
        PoiServices::SoliguideIndex::BATCH_LIMIT = 2
        PoiServices::SoliguideImporter.any_instance.stub(:nb_results) { 4 }

        PoiServices::SoliguideIndex.stub(:post_all_for_page).with(1) { [poi_0, poi_1] }
        PoiServices::SoliguideIndex.stub(:post_all_for_page).with(2) { [poi_2, poi_3] }
      }

      it { expect { subject }.to change { Poi.count }.by(4) }
    end
  end
end
