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
  end

  context 'create' do
    let(:neighborhood) { build :neighborhood }
    let(:fields) { {
        name: neighborhood.name,
        ethics: neighborhood.ethics,
        latitude: neighborhood.latitude,
        longitude: neighborhood.longitude,
        interests: neighborhood.interest_list
    } }

    describe 'not authorized' do
      before { post :create }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      let(:subject) { Neighborhood.last }
      let(:result) { JSON.parse(response.body) }

      before { post :create, params: { token: user.token, neighborhood: fields, format: :json }}

      it { expect(response.status).to eq(201) }
      it { expect(subject.name).to eq neighborhood.name }
      it { expect(subject.latitude).to eq neighborhood.latitude }
      it { expect(subject.longitude).to eq neighborhood.longitude }
      it { expect(result).to have_key("neighborhood") }
      it { expect(result['neighborhood']['name']).to eq("Foot Paris 17è") }
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
          "members" => [],
          "members_count" => 0,
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
          "members_count" => 0,
          "image_url" => nil,
          "interests" => ["sport"],
          "members" => [],
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
        post 'report', params: { token: user.token, id: neighborhood.id, report: { category: 'foo', message: 'bar' } }
      }
      it { expect(response.status).to eq 201 }
    end

    context "missing category" do
      before {
        expect_any_instance_of(SlackServices::SignalNeighborhood).not_to receive(:notify)
        post 'report', params: { token: user.token, id: neighborhood.id, report: { category: '', message: 'bar' } }
      }
      it { expect(response.status).to eq 400 }
    end
  end
end
