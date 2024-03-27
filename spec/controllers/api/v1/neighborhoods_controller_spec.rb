require 'rails_helper'

describe Api::V1::NeighborhoodsController, :type => :controller do
  render_views

  let(:user) { create :pro_user }
  let(:admin) { create(:public_user, admin: true) }
  let(:not_admin) { create(:public_user, admin: false) }

  context 'index' do
    let!(:neighborhood) { create :neighborhood }
    let(:result) { JSON.parse(response.body) }

    before { Neighborhood.stub(:inside_user_perimeter).and_return([neighborhood]) }

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
      let!(:neighborhood) { create :neighborhood, status: :deleted }

      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result).to have_key('neighborhoods') }
      it { expect(result['neighborhoods'].count).to eq(0) }
    end

    describe 'do not get private' do
      let!(:neighborhood) { create :neighborhood, public: false }

      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result).to have_key('neighborhoods') }
      it { expect(result['neighborhoods'].count).to eq(0) }
    end

    describe 'with user roles' do
      before { neighborhood.user.update_attribute(:targeting_profile, :ambassador) }

      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result).to have_key('neighborhoods') }
      it { expect(result['neighborhoods'][0]['user']['community_roles']).to eq(['Ambassadeur']) }
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

    before { Storage::Bucket.any_instance.stub(:public_url_with_size).with(key: "foobar_url", size: :medium) { "path/to/foobar_url" } }

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
          "uuid_v2" => neighborhood.uuid_v2,
          "name" => "new name",
          "name_translations" => {
            "translation" => "new name",
            "original" => "new name",
            "from_lang" => "fr",
            "to_lang" => "fr",
          },
          "description" => "new description",
          "description_translations" => {
            "translation" => "new description",
            "original" => "new description",
            "from_lang" => "fr",
            "to_lang" => "fr",
          },
          "welcome_message" => "new welcome_message",
          "ethics" => "new ethics",
          "image_url" => "path/to/foobar_url",
          "interests" => ["jeux", "nature", "other"],
          "user" => {
            "id" => neighborhood.user_id,
            "lang" => "fr",
            "display_name" => "John D.",
            "avatar_url" => nil,
            "community_roles" => [],
          },
          "address" => {
            "latitude" => 48.86,
            "longitude" => 2.35,
            "display_address" => ""
          },
          "members" => [{
            "id" => 1,
            "lang" => "fr",
            "avatar_url" => "n/a",
            "display_name" => "n/a",
          }],
          "member" => true,
          "members_count" => 1,
          "past_outings_count" => 0,
          "future_outings_count" => 0,
          "has_ongoing_outing" => false,
          "status_changed_at" => nil,
          "public" => true
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
          "uuid_v2" => neighborhood.uuid_v2,
          "name" => "Foot Paris 17è",
          "name_translations" => {
            "translation" => neighborhood.name,
            "original" => neighborhood.name,
            "from_lang" => "fr",
            "to_lang" => "fr",
          },
          "description" => "Pour les passionnés de foot du 17è",
          "description_translations" => {
            "translation" => neighborhood.description,
            "original" => neighborhood.description,
            "from_lang" => "fr",
            "to_lang" => "fr",
          },
          "welcome_message" => nil,
          "member" => false,
          "members_count" => 1,
          "image_url" => nil,
          "interests" => ["sport"],
          "user" => {
            "id" => neighborhood.user_id,
            "lang" => "fr",
            "display_name" => "John D.",
            "avatar_url" => nil,
            "community_roles" => [],
          },
          "address" => {
            "latitude" => 48.86,
            "longitude" => 2.35,
            "display_address" => "",
            "street_address" => nil
          },
          "members" => [{
            "id" => 1,
            "lang" => "fr",
            "display_name" => "n/a",
            "avatar_url" => "n/a"
          }],
          "ethics" => nil,
          "future_outings_count" => 0,
          "outings" => [],
          "past_outings_count" => 0,
          "future_outings" => [],
          "ongoing_outings" => [],
          "has_ongoing_outing" => false,
          "posts" => [],
          "public" => true
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

    describe 'private' do
      let(:neighborhood) { create :neighborhood, public: false }

      before { get :show, params: { id: neighborhood.id, token: user.token } }

      # we dont check anymore whether the user is member or not
      it { expect(response.status).to eq 200 }
    end

    describe 'private but member' do
      let(:neighborhood) { create :neighborhood, public: false }
      let!(:join_request) { create(:join_request, user: user, joinable: neighborhood, status: :accepted) }

      before { get :show, params: { id: neighborhood.id, token: user.token } }

      it { expect(response.status).to eq 200 }
    end

    describe 'with outing' do
      let(:outing) { create :outing, :outing_class, interests: [:sport, :other], metadata: { place_limit: "3" } }
      let(:neighborhood) { create :neighborhood, outings: [outing] }

      before { get :show, params: { id: neighborhood.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result['neighborhood']).to have_key('future_outings') }
      it { expect(result['neighborhood']['future_outings']).to eq([{
        'id' => outing.id,
        'uuid' =>  outing.uuid_v2,
        'uuid_v2' =>  outing.uuid_v2,
        'status' => 'open',
        'title' => outing.title,
        "title_translations" => {
          "translation" => outing.title,
          "original" => outing.title,
          "from_lang" => "fr",
          "to_lang" => "fr",
        },
        'description' => outing.description,
        "description_translations" => {
          "translation" => outing.description,
          "original" => outing.description,
          "from_lang" => "fr",
          "to_lang" => "fr",
        },
        'share_url' => outing.share_url,
        'image_url' => outing.image_url,
        'event_url' => outing.event_url,
        'online' => false,
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
          "portrait_thumbnail_url" => nil,
          "landscape_url" => nil,
          "landscape_thumbnail_url" => nil,
          "street_address" => "44 rue de l’Assomption, 75016 Paris, France",
          "display_address" => "Café la Renaissance, 44 rue de l’Assomption, 75016 Paris",
          "google_place_id" => "foobar",
          "place_limit" => 3
        },
        "interests" => ["sport", "other"],
        "neighborhoods" => [
          { "id" => neighborhood.id, "name" => neighborhood.name }
        ],
        "recurrency" => nil,
        "members_count" => 1,
        "member" => false,
        "confirmed_members_count" => 0,
        "confirmed_member" => false,
        "created_at" => outing.created_at.iso8601(3),
        "updated_at" => outing.updated_at.iso8601(3),
        "status_changed_at" => nil,
        "distance" => nil
      }]) }
    end

    describe 'with online outing created by admin' do
      let!(:online) { create :outing, :outing_class, online: true, user: admin }
      let(:neighborhood) { create :neighborhood }

      before { get :show, params: { id: neighborhood.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result['neighborhood']).to have_key('future_outings') }
      it { expect(result['neighborhood']['future_outings'].count).to eq(1) }
      it { expect(result['neighborhood']['future_outings'][0]['id']).to eq(online.id) }
    end

    describe 'with online outing created by not_admin' do
      let!(:online) { create :outing, :outing_class, online: true, user: not_admin }
      let(:neighborhood) { create :neighborhood }

      before { get :show, params: { id: neighborhood.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result['neighborhood']).to have_key('future_outings') }
      it { expect(result['neighborhood']['future_outings'].count).to eq(0) }
    end

    describe 'with offline outing' do
      let!(:offline) { create :outing, :outing_class, online: false, user: admin }
      let(:neighborhood) { create :neighborhood }

      before { get :show, params: { id: neighborhood.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result['neighborhood']).to have_key('future_outings') }
      it { expect(result['neighborhood']['future_outings'].count).to eq(0) }
    end

    describe 'with chat_message' do
      let(:neighborhood) { create :neighborhood }
      let(:post) { FactoryBot.create(:chat_message, messageable: neighborhood, user: user) }
      let!(:comment) { FactoryBot.create(:chat_message, messageable: neighborhood, user: user, ancestry: "#{post.id}") }

      before { get :show, params: { id: neighborhood.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result['neighborhood']).to have_key('posts') }
      it { expect(result['neighborhood']['posts']).to eq([{
        "id" => post.id,
        "uuid_v2" => post.uuid_v2,
        "content" => post.content,
        "content_translations" => {
          "translation" => post.content,
          "original" => post.content,
          "from_lang" => "fr",
          "to_lang" => "fr",
        },
        "user" => {
          "id" => post.user_id,
          'display_name' => 'John D.',
          "avatar_url" => nil,
          "partner" => nil,
          "partner_role_title" => nil,
          "roles" => []
        },
        "created_at" => post.created_at.iso8601(3),
        "status" => "active",
        "message_type" => "text",
        "post_id" => nil,
        "has_comments" => true,
        "comments_count" => 1,
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

    context 'no deeplink' do
      before { get :show, params: { token: user.token, id: identifier } }

      context 'from id' do
        let(:identifier) { neighborhood.id }

        it { expect(response.status).to eq 200 }
        it { expect(result).to have_key("neighborhood") }
        it { expect(result['neighborhood']['id']).to eq(neighborhood.id) }
      end

      context 'from uuid_v2' do
        let(:identifier) { neighborhood.uuid_v2 }

        it { expect(response.status).to eq 200 }
        it { expect(result).to have_key("neighborhood") }
        it { expect(result['neighborhood']['id']).to eq(neighborhood.id) }
      end
    end

    context 'deeplink' do
      context 'using uuid_v2' do
        before { get :show, params: { token: user.token, id: neighborhood.uuid_v2, deeplink: true } }

        it { expect(response.status).to eq 200 }
        it { expect(result).to have_key('neighborhood') }
        it { expect(result['neighborhood']['id']).to eq(neighborhood.id) }
      end

      context 'using id fails' do
        before { get :show, params: { token: user.token, id: neighborhood.id, deeplink: true } }

        it { expect(response.status).to eq 400 }
      end
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

    ENV['SLACK_SIGNAL'] = '{"url":"https://url.to.slack.com","channel":"channel"}'

    before { stub_request(:post, "https://url.to.slack.com").to_return(status: 200) }

    context "valid params" do
      before {
        expect_any_instance_of(SlackServices::SignalNeighborhood).to receive(:notify)
        post 'report', params: { token: user.token, id: neighborhood.id, report: { signals: ['foo'], message: 'bar' } }
      }
      it { expect(response.status).to eq 201 }
    end

    context "missing signals" do
      before {
        expect_any_instance_of(SlackServices::SignalNeighborhood).not_to receive(:notify)
        post 'report', params: { token: user.token, id: neighborhood.id, report: { signals: [], message: 'bar' } }
      }
      it { expect(response.status).to eq 400 }
    end
  end
end
