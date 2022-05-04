require 'rails_helper'

describe Api::V1::NeighborhoodsController, :type => :controller do
  render_views

  let(:user) { create :pro_user }

  context 'index' do
    let!(:neighborhood) { create :neighborhood }
    let(:result) { JSON.parse(response.body) }

    describe 'not authorized' do
      before { get :index }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result).to have_key('neighborhoods') }
    end

    describe 'joined' do
      let!(:join_request) { create(:join_request, user: user, joinable: neighborhood, status: :accepted) }

      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result).to have_key('neighborhoods') }
      it { expect(result['neighborhoods'].count).to eq(0) }
    end

    describe 'not joined' do
      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result).to have_key('neighborhoods') }
      it { expect(result['neighborhoods'].count).to eq(1) }
      it { expect(result['neighborhoods'][0]['id']).to eq(neighborhood.id) }
    end
  end

  context 'create' do
    let(:neighborhood) { build :neighborhood }
    let(:google_place_id) { 'ChIJQWDurldu5kcRmj2mNTjxtxE' }

    let(:fields) { {
        name: neighborhood.name,
        ethics: neighborhood.ethics,
        latitude: 47.22,
        longitude: -1.55,
        interests: neighborhood.interest_list,
        place_name: '1, place Bouffay, Nantes',
        google_place_id: google_place_id,
    } }
    let(:request) { post :create, params: { token: user.token, neighborhood: fields, format: :json } }

    before { UserServices::AddressService.stub(:fetch_google_place_details).and_return(
      {
        place_name: '174, rue Championnet',
        latitude: 48.86,
        longitude: 2.35,
        postal_code: '75017',
        country: 'FR',
        google_place_id: google_place_id,
      }
    )}

    let(:subject) { Neighborhood.last }
    let(:result) { JSON.parse(response.body) }

    describe 'not authorized' do
      before { post :create }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      before { request }

      it { expect(response.status).to eq(201) }
      it { expect(subject.name).to eq neighborhood.name }
      it { expect(subject.latitude).to eq neighborhood.latitude }
      it { expect(subject.longitude).to eq neighborhood.longitude }
      it { expect(result).to have_key("neighborhood") }
      it { expect(result['neighborhood']['name']).to eq("Foot Paris 17è") }
    end

    describe 'using google_place_id' do
      let(:google_place_id) { 'ChIJQWDurldu5kcRmj2mNTjxtxE' }

      before { request }

      it { expect(subject.id).to eq(result['neighborhood']['id']) }
      it { expect(subject.latitude).to eq(48.86) }
      it { expect(subject.longitude).to eq(2.35) }
      it { expect(subject.place_name).to eq("174, rue Championnet") }
      it { expect(subject.google_place_id).to eq("ChIJQWDurldu5kcRmj2mNTjxtxE") }
    end

    describe 'using place_name, latitude, longitude' do
      let(:google_place_id) { nil }

      before { request }

      it { expect(subject.latitude).to eq(47.22) }
      it { expect(subject.longitude).to eq(-1.55) }
      it { expect(subject.place_name).to eq("1, place Bouffay, Nantes") }
      it { expect(subject.google_place_id).to eq("") }
    end

    describe 'Neighborhood and JoinRequest are created on success' do
      it { expect { request }.to change { Neighborhood.count }.by(1) }
      it { expect { request }.to change { JoinRequest.count }.by(1) }
    end

    describe 'Neighborhood and JoinRequest are not created on failure' do
      before { JoinRequest.stub(:create!).and_raise("ValidationError") }
      it { expect { request }.to change { Neighborhood.count }.by(0) }
      it { expect { request }.to change { JoinRequest.count }.by(0) }
    end
  end

  describe 'PATCH update' do
    let(:neighborhood) { FactoryBot.create(:neighborhood) }
    let(:neighborhood_image) { FactoryBot.create(:neighborhood_image) }

    context "not signed in" do
      before { patch :update, params: { id: neighborhood.to_param, neighborhood: { name: "new name" } } }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      before { patch :update, params: { id: neighborhood.to_param, neighborhood: { name: "new name" } } }

      context "user is not creator" do
        before { patch :update, params: { id: neighborhood.to_param, neighborhood: { name: "new name" }, token: user.token } }
        it { expect(response.status).to eq(401) }
      end

      context "user is creator" do
        let(:neighborhood) { FactoryBot.create(:neighborhood, user: user) }
        let(:result) { JSON.parse(response.body) }

        before {
          Storage::Bucket.any_instance.stub(:url_for).with(key: "foobar_url") { "path/to/foobar_url" }

          patch :update, params: { id: neighborhood.to_param, neighborhood: {
            name: "new name",
            ethics: "new ethics",
            description: "new description",
            welcome_message: "new welcome_message",
            neighborhood_image_id: neighborhood_image.id,
            interests: ["jeux", "nature", "other"],
            other_interest: "foo"
          }, token: user.token }
        }
        it { expect(response.status).to eq(200) }
        it { expect(result["neighborhood"]).to eq({
          "id" => neighborhood.id,
          "name" => "new name",
          "description" => "new description",
          "welcome_message" => "new welcome_message",
          "ethics" => "new ethics",
          "image_url" => "path/to/foobar_url",
          "interests" => ["jeux", "nature", "other"],
          "user" => {
            "id" => neighborhood.user_id,
            "display_name" => "John D.",
            "avatar_url" => nil
          },
          "address" => {
            "latitude" => 48.86,
            "longitude" => 2.35,
            "display_address" => ""
          },
          "members" => [{
            "id" => user.id,
            "display_name" => "John D.",
            "avatar_url" => nil,
          }],
          "members_count" => 1,
          "past_outings_count" => 0,
          "future_outings_count" => 0,
          "has_ongoing_outing" => false,
        }) }
      end
    end
  end

  context 'show' do
    let(:neighborhood) { create :neighborhood }

    describe 'not authorized' do
      before { get :show, params: { id: neighborhood.id } }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      before { get :show, params: { id: neighborhood.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(JSON.parse(response.body)).to eq({
        "neighborhood" => {
          "id" => neighborhood.id,
          "name" => "Foot Paris 17è",
          "description" => nil,
          "welcome_message" => nil,
          "members_count" => 1,
          "image_url" => nil,
          "interests" => ["sport"],
          "user" => {
            "id" => neighborhood.user_id,
            "display_name" => "John D.",
            "avatar_url" => nil
          },
          "address" => {
            "latitude" => 48.86,
            "longitude" => 2.35,
            "display_address" => ""
          },
          "members" => [{
            "id" => neighborhood.user.id,
            "display_name" => "John D.",
            "avatar_url" => nil,
          }],
          "ethics" => nil,
          "past_outings_count" => 0,
          "future_outings_count" => 0,
          "has_ongoing_outing" => false
        }
      })}
    end
  end

  context 'joined' do
    let(:joined) { create :neighborhood }
    let(:not_joined) { create :neighborhood }

    let!(:join_request) { create(:join_request, user: user, joinable: joined, status: :accepted) }

    let(:result) { JSON.parse(response.body) }

    describe 'not authorized' do
      before { get :joined }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      before { get :joined, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result).to have_key('neighborhoods') }
      it { expect(result['neighborhoods'].count).to eq(1) }
      it { expect(result['neighborhoods'][0]['id']).to eq(joined.id) }
    end
  end
end
