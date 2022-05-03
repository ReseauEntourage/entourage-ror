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
    let(:fields) { {
        name: neighborhood.name,
        ethics: neighborhood.ethics,
        latitude: neighborhood.latitude,
        longitude: neighborhood.longitude,
        interests: neighborhood.interest_list,
        google_place_id: 'ChIJQWDurldu5kcRmj2mNTjxtxE'
    } }
    let(:request) { post :create, params: { token: user.token, neighborhood: fields, format: :json } }

    before { UserServices::AddressService.stub(:fetch_google_place_details).and_return(
      {
        place_name: '174, rue Championnet',
        latitude: 48.86,
        longitude: 2.35,
        postal_code: '75017',
        country: 'FR',
        google_place_id: 'ChIJQWDurldu5kcRmj2mNTjxtxE',
      }
    )}

    describe 'not authorized' do
      before { post :create }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      let(:subject) { Neighborhood.last }
      let(:result) { JSON.parse(response.body) }

      before { request }

      it { expect(response.status).to eq(201) }
      it { expect(subject.name).to eq neighborhood.name }
      it { expect(subject.latitude).to eq neighborhood.latitude }
      it { expect(subject.longitude).to eq neighborhood.longitude }
      it { expect(result).to have_key("neighborhood") }
      it { expect(result['neighborhood']['name']).to eq("Foot Paris 17è") }
      it { expect(result['neighborhood']['address']['display_address']).to eq("174, rue Championnet, 75017") }
      it { expect(result['neighborhood']['address']['latitude']).to eq(48.86) }
      it { expect(result['neighborhood']['address']['longitude']).to eq(2.35) }
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

  describe 'POST #report' do
    let(:neighborhood) { create :neighborhood }

    ENV['SLACK_SIGNAL_NEIGHBORHOOD_WEBHOOK'] = '{"url":"https://url.to.slack.com","channel":"channel","username":"signal-neighborhood"}'

    before { stub_request(:post, "https://url.to.slack.com").to_return(status: 200) }

    context "valid params" do
      before {
        expect_any_instance_of(SlackServices::SignalNeighborhood).to receive(:notify)
        post 'report', params: { token: user.token, id: neighborhood.id, report: { message: 'message' } }
      }
      it { expect(response.status).to eq 201 }
    end

    context "missing message" do
      before {
        expect_any_instance_of(SlackServices::SignalNeighborhood).not_to receive(:notify)
        post 'report', params: { token: user.token, id: neighborhood.id, report: { message: '' } }
      }
      it { expect(response.status).to eq 400 }
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
