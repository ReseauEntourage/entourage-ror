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

    describe 'do not get deleted' do
      let!(:deleted) { create :neighborhood, status: :deleted }

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
    let(:interests) { neighborhood.interest_list }
    let(:other_interest) { nil }

    let(:fields) { {
        name: neighborhood.name,
        description: neighborhood.description,
        ethics: neighborhood.ethics,
        latitude: 47.22,
        longitude: -1.55,
        interests: interests,
        other_interest: other_interest,
        place_name: '1, place Bouffay, Nantes',
        google_place_id: google_place_id,
    } }
    let(:request) { post :create, params: { token: user.token, neighborhood: fields, format: :json } }

    before { UserServices::AddressService.stub(:get_google_place_details).and_return(
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
      it { expect(subject.google_place_id).to eq(nil) }
    end

    describe 'with "other" interest, other_interest field is optionnal' do
      let(:interests) { [:sport, :other] }
      let(:other_interest) { "my other interest" }

      before { request }

      it { expect(response.status).to eq(201) }
      it { expect(subject.other_interest).to eq "my other interest" }
    end

    describe 'with "other" interest, other_interest field is not required' do
      let(:interests) { [:sport, :other] }
      let(:other_interest) { nil }

      before { request }

      it { expect(response.status).to eq(201) }
      it { expect(subject.other_interest).to be_blank }
    end

    describe 'without "other" interest, other_interest is always nil' do
      let(:interests) { [:sport] }
      let(:other_interest) { "my other interest" }

      before { request }

      it { expect(response.status).to eq(201) }
      it { expect(subject.other_interest).to be_blank }
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
    let(:result) { JSON.parse(response.body) }
    let(:subject) { Neighborhood.find(neighborhood.id) }

    before { Storage::Bucket.any_instance.stub(:public_url).with(key: "foobar_url") { "path/to/foobar_url" } }

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

        before { patch :update, params: { id: neighborhood.to_param, neighborhood: {
          name: "new name",
          ethics: "new ethics",
          description: "new description",
          welcome_message: "new welcome_message",
          neighborhood_image_id: neighborhood_image.id,
          interests: ["jeux", "nature", "other"],
          other_interest: "foo"
        }, token: user.token } }

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
          "member" => true,
          "members_count" => 1,
          "past_outings_count" => 0,
          "future_outings_count" => 0,
          "has_ongoing_outing" => false,
        }) }
      end

      context "user is creator, one field updated" do
        let(:neighborhood) { FactoryBot.create(:neighborhood, user: user) }

        before { patch :update, params: { id: neighborhood.to_param, neighborhood: { name: "new name" }, token: user.token } }

        it { expect(response.status).to eq(200) }
        it { expect(subject.name).to eq("new name") }
      end

      describe 'with "other" interest, other_interest field is always nil' do
        let(:neighborhood) { FactoryBot.create(:neighborhood, user: user) }

        before { patch :update, params: { id: neighborhood.to_param, neighborhood: { interests: [:sport, :other], other_interest: 'foo' }, token: user.token } }

        it { expect(response.status).to eq(200) }
        it { expect(subject.other_interest).to eq(nil) }
      end

      describe 'without "other" interest, other_interest is always nil' do
        let(:neighborhood) { FactoryBot.create(:neighborhood, user: user) }

        before { patch :update, params: { id: neighborhood.to_param, neighborhood: { interests: [:cuisine], other_interest: 'foo' }, token: user.token } }

        it { expect(response.status).to eq(200) }
        it { expect(subject.other_interest).to eq(nil) }
      end
    end
  end

  context 'show' do
    let(:neighborhood) { create :neighborhood }

    let(:result) { JSON.parse(response.body) }

    describe 'not authorized' do
      before { get :show, params: { id: neighborhood.id } }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      before { get :show, params: { id: neighborhood.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result).to eq({
        "neighborhood" => {
          "id" => neighborhood.id,
          "name" => "Foot Paris 17è",
          "description" => "Pour les passionnés de foot du 17è",
          "welcome_message" => nil,
          "member" => false,
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
            "display_address" => "",
            "street_address" => nil
          },
          "members" => [{
            "id" => neighborhood.user.id,
            "display_name" => "John D.",
            "avatar_url" => nil,
          }],
          "ethics" => nil,
          "past_outings_count" => 0,
          "future_outings_count" => 0,
          "future_outings" => [],
          "ongoing_outings" => [],
          "has_ongoing_outing" => false,
          "posts" => []
        }
      })}
    end

    describe 'is member' do
      let!(:join_request) { create(:join_request, user: user, joinable: neighborhood, status: :accepted, last_message_read: nil) }

      before { Timecop.freeze }
      before { get :show, params: { id: neighborhood.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result['neighborhood']['member']).to eq(true) }
      it { expect(join_request.reload.last_message_read.to_s).to eq Time.now.in_time_zone.to_s }
    end

    describe 'with outing' do
      let(:outing) { create :outing, :for_neighborhood, interests: [:sport, :other] }
      let(:neighborhood) { create :neighborhood, outings: [outing] }

      before { get :show, params: { id: neighborhood.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result['neighborhood']).to have_key('future_outings') }
      it { expect(result['neighborhood']['future_outings']).to eq([{
        'id' => outing.id,
        'uuid' =>  outing.uuid_v2,
        'title' => outing.title,
        'description' => outing.description,
        'share_url' => outing.share_url,
        'image_url' => outing.image_url,
        'event_url' => outing.event_url,
        'author' => {
          'id' => outing.user_id,
          'display_name' => 'John D.',
          'avatar_url' => nil,
          "partner" => nil,
          "partner_role_title" => nil,
        },
        "metadata" => {
          "ends_at" => 1.day.from_now.change(hour: 22).iso8601(3),
          "starts_at" => 1.day.from_now.change(hour: 19).iso8601(3),
          "place_name" => "Café la Renaissance",
          "previous_at" => nil,
          "portrait_url" => nil,
          "landscape_url" => nil,
          "street_address" => "44 rue de l’Assomption, 75016 Paris, France",
          "display_address" => "Café la Renaissance, 44 rue de l’Assomption, 75016 Paris",
          "google_place_id" => "foobar",
          "portrait_thumbnail_url" => nil,
          "landscape_thumbnail_url" => nil,
          "place_limit" => nil
        },
        "interests" => ["sport", "other"]
      }]) }
    end

    describe 'with chat_message' do
      let(:neighborhood) { create :neighborhood }
      let!(:chat_message) { FactoryBot.create(:chat_message, messageable: neighborhood, user: user) }

      before { get :show, params: { id: neighborhood.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result['neighborhood']).to have_key('posts') }
      it { expect(result['neighborhood']['posts']).to eq([{
        "id" => chat_message.id,
        "content" => chat_message.content,
        "user" => {
          "id" => chat_message.user_id,
          'display_name' => 'John D.',
          "avatar_url" => nil,
          "partner" => nil,
        },
        "created_at" => chat_message.created_at.iso8601(3),
        "message_type" => "text",
        "post_id" => nil,
        "has_comments" => false,
        "comments_count" => 0,
        "image_url" => nil,
        "read" => nil,
      }]) }
    end

    describe 'is member with chat_message' do
      let!(:join_request) { create(:join_request, user: user, joinable: neighborhood, status: :accepted) }
      let!(:chat_message) { FactoryBot.create(:chat_message, messageable: neighborhood, user: user) }

      before { get :show, params: { id: neighborhood.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result['neighborhood']).to have_key('posts') }
      it { expect(result['neighborhood']['posts'][0]["read"]).to eq(false) }
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

  context 'destroy' do
    let(:creator) { create :pro_user }
    let(:neighborhood) { create :neighborhood, user: creator }

    let(:result) { Neighborhood.unscoped.find(neighborhood.id) }

    describe 'not authorized' do
      before { delete :destroy, params: { id: neighborhood.id } }

      it { expect(response.status).to eq 401 }
      it { expect(result.status).to eq 'active' }
    end

    describe 'not authorized cause should be creator' do
      before { delete :destroy, params: { id: neighborhood.id, token: user.token } }

      it { expect(response.status).to eq 401 }
      it { expect(result.status).to eq 'active' }
    end

    describe 'authorized' do
      let(:creator) { user }

      before { delete :destroy, params: { id: neighborhood.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result.status).to eq 'deleted' }
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
