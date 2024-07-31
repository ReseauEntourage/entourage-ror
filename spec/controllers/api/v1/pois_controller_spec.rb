require 'rails_helper'

describe Api::V1::PoisController, :type => :controller do
  render_views

  context 'authorized' do
    let!(:user) { create :pro_user }

    describe 'create' do
      let(:poi) { build :poi }
      let(:poi_params) { {
        form_response: {
          definition: {
            fields: [
              { id: "1", title: "Nom de la structure" },
              { id: "2", title: "Adresse exacte " },
              { id: "3", title: "Description" },
              { id: "4", title: "Site Internet ou page Facebook" },
              { id: "5", title: "Téléphone de la structure" },
              { id: "6", title: "Email de la structure" },
              { id: "7", title: "Votre email" },
            ]
          },
          answers: [
            { text: poi.name, field: { id: "1" } },
            { text: poi.adress, field: { id: "2" } },
            { text: "mydescription", field: { id: "3" } },
            { text: poi.website, field: { id: "4" } },
            { text: poi.phone, field: { id: "5" } },
            { text: poi.email, field: { id: "6" } },
            { text: "john@foo.bar", field: { id: "7" } },
          ]
        }
      } }

      let(:subject) { post :create, params: { format: :json }.merge(poi_params) }

      describe "stub verify" do
        before { PoiServices::Typeform.any_instance.stub(:verify) { true } }
        before { subject }

        it { expect(response.status).to eq(201) }
        it { expect(Poi.last.name).to eq poi.name }
        it { expect(Poi.last.latitude).to eq poi.latitude }
        it { expect(Poi.last.longitude).to eq poi.longitude }
        it { expect(Poi.last.adress).to eq poi.adress }
        it { expect(Poi.last.phone).to eq poi.phone }
        it { expect(Poi.last.website).to eq poi.website }
        it { expect(Poi.last.email).to eq poi.email }
        it { expect(Poi.last.audience).to eq nil }
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
            "description"=>"mydescription",
            "longitude"=>2.30681949999996,
            "latitude"=>48.870424,
            "address"=>"Au 50 75008 Paris",
            "phone"=>"0000000000",
            "website"=>"entourage.com",
            "email"=>"entourage@entourage.com",
            "audience"=>nil,
            "hours"=>nil,
            "languages"=>nil,
            "partner_id"=>nil,
            "category_ids"=>[poi.category_id]
          })
        end
      end

      describe "do not stub verify" do
        let(:secret) { "foo" }

        before { ENV['POI_FORM_SECRET_TOKEN'] = secret }
        before { request.headers["Typeform-Signature"] = "sha256=#{PoiServices::Typeform.base64_hash(secret, poi_params.to_query)}" }

        before { subject }

        it { expect(response.status).to eq(201) }
        it { expect(Poi.last.name).to eq poi.name }
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
          post :report, params: { id: poi.id, token: user.token, message: message, format: :json }
        end
        it { expect(response.status).to eq(201) }
        it { expect(member_mailer).to have_received(:poi_report).with poi, user, message }
        it { expect(mail).to have_received(:deliver_later).with no_args }
        it { expect(JSON.parse(response.body)).to have_key('message') }
      end

      describe 'wrong poi id' do
        before { post :report, params: { id: -1, token: user.token, message: message, format: :json } }
        it { expect(response.status).to eq(404) }
      end

      describe 'no message' do
        before { post :report, params: { id: poi.id, token: user.token, format: :json } }
        it { expect(response.status).to eq(400) }
      end
    end

    describe 'show' do
      let(:poi) { create :poi }
      before { get 'show', params: { id: poi.id, token: user.token } }
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
          before { get 'index', params: { category_ids: [category1.id, category2.id].join(","), :format => :json } }
          it { expect(assigns(:categories)).to eq([category1, category2, category3]) }
          it { expect(assigns(:pois)).to eq([poi1, poi3]) }

          it "renders POI" do
            res = JSON.parse(response.body)
            expect(res).to eq({
              "categories" => [{
                "id" => category1.id,
                "name" => category1.name
              }, {
                "id" => category2.id,
                "name" => category2.name
              }, {
                "id" => category3.id,
                "name" => category3.name
              }
              ],
              "pois" => [{
                "id" => poi1.id,
                "name" => "Dede",
                "description" => nil,
                "longitude" => 2.30681949999996,
                "latitude" => 48.870424,
                "adress" => "Au 50 75008 Paris",
                "phone" => "0000000000",
                "website" => "entourage.com",
                "email" => "entourage@entourage.com",
                "audience" => "Mon audience",
                "validated" => true,
                "category_id" => poi1.category_id,
                "category" => {
                  "id" => poi1.category.id,
                  "name" => poi1.category.name
                },
                "partner_id" => nil
              }, {
                "id" => poi3.id,
                "name" => "Dede",
                "description" => nil,
                "longitude" => 2.30681949999996,
                "latitude" => 48.870424,
                "adress" => "Au 50 75008 Paris",
                "phone" => "0000000000",
                "website" => "entourage.com",
                "email" => "entourage@entourage.com",
                "audience" => "Mon audience",
                "validated" => true,
                "category_id" => poi3.category_id,
                "category" => {
                  "id" => poi3.category.id,
                  "name" => poi3.category.name
                },
                "partner_id" => nil
              }
            ]
          })
          end
        end

        context 'v2' do
          before { get 'index', params: { category_ids: [category1.id, category2.id].join(","), v: 2 } }
          it "renders POI" do
            res = JSON.parse(response.body)
            expect(res).to eq(
              "pois" => [{
                "uuid" => poi1.uuid,
                "name" => "Dede",
                "longitude" => 2.30681949999996,
                "latitude" => 48.870424,
                "address" => "Au 50 75008 Paris",
                "phone" => "0000000000",
                "category_id" => poi1.category_id,
                "partner_id" => nil
              }, {
                "uuid" => poi3.uuid,
                "name" => "Dede",
                "longitude" => 2.30681949999996,
                "latitude" => 48.870424,
                "address" => "Au 50 75008 Paris",
                "phone" => "0000000000",
                "category_id" => poi3.category_id,
                "partner_id" => nil
              }]
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
          before { get :index, params: { latitude: 10.0, longitude: 10.0, format: :json } }
          it { expect(response.status).to eq(200) }
          it { expect(assigns[:pois].map(&:id).sort).to eq [poi3, poi4].map(&:id).sort }
        end

        context 'with distance' do
          before { get :index, params: { latitude: 10.0, longitude: 10.0, distance: 40.0, format: :json } }
          it { expect(response.status).to eq(200) }
          it { expect(assigns[:pois].map(&:id).sort).to eq [poi3, poi4, poi2].map(&:id).sort }
        end
      end

      context 'soliguide redirection' do
        let!(:option_soliguide) { FactoryBot.create(:option_soliguide, active: active) }

        paris = PoiServices::Soliguide::PARIS
        params = { latitude: paris[:latitude], longitude: paris[:longitude], distance: 5, v: '2', format: :json }

        before {
          stub_request(:post, "https://api.soliguide.fr/new-search").to_return(status: 200, body: '{"places":[{}]}', headers: {})
        }

        context 'redirects to soliguide when Paris and soliguide option is defined' do
          let!(:active) { true }

          before {
            expect(PoiServices::SoliguideFormatter).not_to receive(:format_short)
            expect(PoiServices::SoliguideIndex).to receive(:post_only_query)
            get :index, params: params
          }

          it { expect(response.status).to eq 200 }
          it { expect(JSON.parse(response.body)).to have_key("pois") }
        end

        context 'does not redirect to soliguide when Paris and soliguide option is not defined' do
          let!(:active) { false }

          before {
            expect(PoiServices::SoliguideFormatter).not_to receive(:format_short)
            expect(PoiServices::SoliguideIndex).not_to receive(:post_only_query)
            get :index, params: params
          }

          it { expect(response.status).to eq 200 }
          it { expect(JSON.parse(response.body)).to have_key("pois") }
        end
      end
    end
  end

  describe "clustered" do
    let(:user) { create :pro_user }
    let(:result) { JSON.parse(response.body) }

    let!(:poi1) { create :poi, latitude: 10, longitude: 12 }
    let!(:poi2) { create :poi, latitude: 9.9, longitude: 10.1 }
    let!(:poi3) { create :poi, latitude: 10, longitude: 10 }
    let!(:poi4) { create :poi, latitude: 10.05, longitude: 9.95 }
    let!(:poi5) { create :poi, latitude: 12, longitude: 10 }

    before { get :clusters, params: { token: user.token, latitude: 10.0, longitude: 10.0, distance: 40.0, format: :json } }

    it { expect(response.status).to eq(200) }
    it { expect(result).to have_key("clusters") }
    it { expect(result["clusters"].length).to eq(3) }
    it { expect(result["clusters"].map{|cluster| cluster["id"]}).to match_array([poi3.id, poi4.id, poi2.id]) }
  end
end
