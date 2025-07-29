require 'rails_helper'

describe Api::V1::ResourcesController, type: :controller do
  render_views

  let(:user) { create :pro_user }

  describe 'index' do
    let!(:resource) { create :resource }
    let(:result) { JSON.parse(response.body) }

    describe 'not authorized' do
      before { get :index }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result).to have_key('resources') }
      it { expect(result['resources'].count).to eq(1) }
    end

    describe 'no param nohtml' do
      let(:subject) { result['resources'][0] }

      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(subject).to have_key('html') }
    end

    describe 'with param nohtml' do
      let(:subject) { result['resources'][0] }

      before { get :index, params: { token: user.token, nohtml: true } }

      it { expect(response.status).to eq 200 }
      it { expect(subject).not_to have_key('html') }
    end
  end

  describe 'home' do
    let(:result) { JSON.parse(response.body) }
    let(:user) { create :pro_user, goal: goal }
    let!(:resource) { create :resource, pin_ask_for_help: pin_ask_for_help, pin_offer_help: pin_offer_help }
    let(:pin_ask_for_help) { false }
    let(:pin_offer_help) { false }

    before { get :home, params: { token: user.token } }

    describe 'resource is pinned for ask_for_help user' do
      let(:goal) { :ask_for_help }
      let(:pin_ask_for_help) { true }

      it { expect(response.status).to eq 200 }
      it { expect(result).to have_key('resources') }
      it { expect(result['resources'].count).to eq(1) }
    end

    describe 'resource is not pinned for ask_for_help user' do
      let(:goal) { :ask_for_help }

      it { expect(response.status).to eq 200 }
      it { expect(result).to have_key('resources') }
      it { expect(result['resources'].count).to eq(0) }
    end

    describe 'resource is pinned for offer_help user' do
      let(:goal) { :offer_help }
      let(:pin_offer_help) { true }

      it { expect(response.status).to eq 200 }
      it { expect(result).to have_key('resources') }
      it { expect(result['resources'].count).to eq(1) }
    end

    describe 'resource is not pinned for offer_help user' do
      let(:goal) { :offer_help }

      it { expect(response.status).to eq 200 }
      it { expect(result).to have_key('resources') }
      it { expect(result['resources'].count).to eq(0) }
    end
  end

  describe 'show' do
    let(:resource) { create :resource }

    let(:result) { JSON.parse(response.body) }

    describe 'not authorized' do
      before { get :show, params: { id: resource.id } }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      let(:request) { get :show, params: { id: resource.id, token: user.token } }

      before { ResourceServices::Format.any_instance.stub(:to_html) { '<title>foo</title>' } }

      context 'user_resource is created' do
        it { expect { request }.to change { UsersResource.count }.by(1) }
      end

      context 'response' do
        before { request }

        it { expect(response.status).to eq 200 }
        it { expect(result).to eq({
          'resource' => {
            'id' => resource.id,
            'uuid_v2' => resource.uuid_v2,
            'name' => 'Comment aider',
            'is_video' => false,
            'duration' => nil,
            'category' => 'understand',
            'description' => nil,
            'image_url' => nil,
            'url' => nil,
            'watched' => false,
            'html' => '<title>foo</title>'
          }
        })}
        it { expect(user.users_resources.count).to eq(1) }
        it { expect(user.users_resources.first.resource_id).to eq(resource.id) }
      end
    end

    context 'no deeplink' do
      before { get :show, params: { token: user.token, id: identifier } }

      context 'from id' do
        let(:identifier) { resource.id }

        it { expect(response.status).to eq 200 }
        it { expect(result).to have_key('resource') }
        it { expect(result['resource']['id']).to eq(resource.id) }
      end

      context 'from uuid_v2' do
        let(:identifier) { resource.uuid_v2 }

        it { expect(response.status).to eq 200 }
        it { expect(result).to have_key('resource') }
        it { expect(result['resource']['id']).to eq(resource.id) }
      end
    end

    context 'deeplink' do
      context 'using uuid_v2' do
        before { get :show, params: { token: user.token, id: resource.uuid_v2, deeplink: true } }

        it { expect(response.status).to eq 200 }
        it { expect(result).to have_key('resource') }
        it { expect(result['resource']['id']).to eq(resource.id) }
      end

      context 'using id fails' do
        before { get :show, params: { token: user.token, id: resource.id, deeplink: true } }

        it { expect(response.status).to eq 400 }
      end
    end

    describe 'description' do
      let(:resource) { create :resource, description: '<p>foo</p>', is_video: false }
      before { get :show, params: { id: resource.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result['resource']['html']).to include(
        '<p>foo</p>'
      )}
    end
  end

  describe 'tag' do
    let(:resource) { create :resource, tag: :foo }

    let(:result) { JSON.parse(response.body) }

    before { get :tag, params: { token: user.token, tag: resource.tag } }

    it { expect(response.status).to eq 200 }
    it { expect(result).to have_key('resource') }
    it { expect(result['resource']['id']).to eq(resource.id) }
  end
end
