require 'rails_helper'

describe Api::V1::PoisController, :type => :controller do
  render_views

  context 'authorized' do
    let!(:user) { create :pro_user }

    describe 'create' do
      let!(:poi) { build :poi }
      before { post :create, token: user.token, poi: { name: poi.name, latitude: poi.latitude, longitude: poi.longitude, adress: poi.adress, phone: poi.phone, website: poi.website, email: poi.email, audience: poi.audience, category_id: poi.category_id }, format: :json}
      it { expect(response.status).to eq(201) }
      it { expect(Poi.last.name).to eq poi.name }
      it { expect(Poi.last.latitude).to eq poi.latitude }
      it { expect(Poi.last.longitude).to eq poi.longitude }
      it { expect(Poi.last.adress).to eq poi.adress }
      it { expect(Poi.last.phone).to eq poi.phone }
      it { expect(Poi.last.website).to eq poi.website }
      it { expect(Poi.last.email).to eq poi.email }
      it { expect(Poi.last.audience).to eq poi.audience }
      it { expect(Poi.last.category).to eq poi.category }
      it { expect(Poi.last.validated).to be false }

      it "renders POI" do
        poi = Poi.last
        res = JSON.parse(response.body)
        expect(res).to eq("poi"=>{
          "uuid"=>poi.id.to_s,
          "source"=>"entourage",
          "source_url"=>nil,
          "name"=>"Dede",
          "description"=>nil,
          "longitude"=>2.30681949999996,
          "latitude"=>48.870424,
          "address"=>"Au 50 75008 Paris",
          "phone"=>"0000000000",
          "website"=>"entourage.com",
          "email"=>"entourage@entourage.com",
          "audience"=>"Mon audience",
          "hours"=>nil,
          "languages"=>nil,
          "partner_id"=>nil,
          "category_ids"=>[poi.category_id]
        })
      end
    end

    describe 'report' do
      let!(:poi) { create :poi }
      let!(:mail) { spy('mail') }
      let!(:member_mailer) { spy('member_mailer', poi_report: mail) }
      let!(:message) { 'message' }

      describe 'correct request' do
        before do
          controller.member_mailer = member_mailer
          post :report, id: poi.id, token: user.token, message: message, format: :json
        end
        it { expect(response.status).to eq(201) }
        it { expect(member_mailer).to have_received(:poi_report).with poi, user, message }
        it { expect(mail).to have_received(:deliver_later).with no_args }
      end

      describe 'wrong poi id' do
        before { post :report, id: -1, token: user.token, message: message, format: :json }
        it { expect(response.status).to eq(404) }
      end

      describe 'no message' do
        before { post :report, id: poi.id, token: user.token, format: :json }
        it { expect(response.status).to eq(400) }
      end
    end

    describe 'show' do
      let(:poi) { create :poi }
      before { get 'show', id: poi.id, token: user.token }
      it { expect(response.status).to eq 200 }
      it { expect(JSON.parse(response.body)).to eq(
        "poi" => {
          "uuid" => poi.id.to_s,
          "source" => "entourage",
          "source_url" => nil,
          "name" => "Dede",
          "description" => nil,
          "longitude" => 2.30681949999996,
          "latitude" => 48.870424,
          "address" => "Au 50 75008 Paris",
          "phone" => "0000000000",
          "website" => "entourage.com",
          "email" => "entourage@entourage.com",
          "audience" => "Mon audience",
          "hours" => nil,
          "languages" => nil,
          "partner_id" => nil,
          "category_ids" => [poi.category_id]
        }
      )}
    end
  end

  context "unauthorized" do
    describe 'index' do
      context 'serialization' do
        let!(:category1) { create :category }
        let!(:category2) { create :category }
        let!(:category3) { create :category }
        let!(:poi1) { create :poi, category: category1, validated: true }
        let!(:poi2) { create :poi, category: category2, validated: false }
        let!(:poi3) { create :poi, category: category2, validated: true }
        let!(:poi4) { create :poi, category: category3, validated: true }

        context 'v1' do
          before { get 'index', category_ids: [category1.id, category2.id].join(","), :format => :json }
          it { expect(assigns(:categories)).to eq([category1, category2, category3]) }
          it { expect(assigns(:pois)).to eq([poi1, poi3]) }

          it "renders POI" do
            res = JSON.parse(response.body)
            expect(res).to eq({"categories"=>[
                {"id"=>category1.id, "name"=>category1.name},
                {"id"=>category2.id, "name"=>category2.name},
                {"id"=>category3.id, "name"=>category3.name}],
                               "pois"=>[
                                   {"id"=>poi1.id,
                                    "name"=>"Dede",
                                    "description"=>nil,
                                    "longitude"=>2.30681949999996,
                                    "latitude"=>48.870424,
                                    "adress"=>"Au 50 75008 Paris",
                                    "phone"=>"0000000000",
                                    "website"=>"entourage.com",
                                    "email"=>"entourage@entourage.com",
                                    "audience"=>"Mon audience",
                                    "validated"=>true,
                                    "category_id"=>poi1.category_id,
                                    "category"=>{"id"=>poi1.category.id, "name"=>poi1.category.name},
                                    "partner_id"=>nil},
                                   {"id"=>poi3.id,
                                    "name"=>"Dede",
                                    "description"=>nil,
                                    "longitude"=>2.30681949999996,
                                    "latitude"=>48.870424,
                                    "adress"=>"Au 50 75008 Paris",
                                    "phone"=>"0000000000",
                                    "website"=>"entourage.com",
                                    "email"=>"entourage@entourage.com",
                                    "audience"=>"Mon audience",
                                    "validated"=>true,
                                    "category_id"=>poi3.category_id,
                                    "category"=>{"id"=>poi3.category.id, "name"=>poi3.category.name},
                                    "partner_id"=>nil}
                               ]})
          end
        end

        context 'v2' do
          before { get 'index', category_ids: [category1.id, category2.id].join(","), v: 2 }
          it "renders POI" do
            res = JSON.parse(response.body)
            expect(res).to eq(
              "pois"=>[
                {
                  "uuid"=>poi1.uuid,
                  "name"=>"Dede",
                  "longitude"=>2.30681949999996,
                  "latitude"=>48.870424,
                  "address"=>"Au 50 75008 Paris",
                  "phone"=>"0000000000",
                  "category_id"=>poi1.category_id,
                  "partner_id"=>nil
                },
                {
                  "uuid"=>poi3.uuid,
                  "name"=>"Dede",
                  "longitude"=>2.30681949999996,
                  "latitude"=>48.870424,
                  "address"=>"Au 50 75008 Paris",
                  "phone"=>"0000000000",
                  "category_id"=>poi3.category_id,
                  "partner_id"=>nil
                }
              ]
            )
          end
        end
      end

      context 'with location parameters' do
        let!(:poi1) { create :poi, latitude: 10, longitude: 12 }
        let!(:poi2) { create :poi, latitude: 9.9, longitude: 10.1 }
        let!(:poi3) { create :poi, latitude: 10, longitude: 10 }
        let!(:poi4) { create :poi, latitude: 10.05, longitude: 9.95 }
        let!(:poi5) { create :poi, latitude: 12, longitude: 10 }

        context 'without distance' do
          before { get :index, latitude: 10.0, longitude: 10.0, format: :json }
          it { expect(response.status).to eq(200) }
          it { expect(assigns[:pois]).to eq [poi3, poi4] }
        end

        context 'with distance' do
          before { get :index, latitude: 10.0, longitude: 10.0, distance: 40.0, format: :json }
          it { expect(response.status).to eq(200) }
          it { expect(assigns[:pois]).to eq [poi3, poi4, poi2] }
        end
      end
    end
  end
end
