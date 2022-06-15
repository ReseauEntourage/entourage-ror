require 'rails_helper'

describe Api::V1::ResourcesController, :type => :controller do
  render_views

  let(:user) { create :pro_user }

  context 'index' do
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
    end
  end

  context 'show' do
    let(:resource) { create :resource }

    let(:result) { JSON.parse(response.body) }

    describe 'not authorized' do
      before { get :show, params: { id: resource.id } }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      before { ResourceServices::Format.any_instance.stub(:to_html) { '<title>foo</title>' } }
      before { get :show, params: { id: resource.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result).to eq({
        "resource" => {
          "id" => resource.id,
          "name" => "Comment aider",
          "is_video" => false,
          "duration" => nil,
          "category" => "understand",
          "description" => nil,
          "image_url" => nil,
          "url" => nil,
          "watched" => false,
          "html" => "<title>foo</title>"
        }
      })}
    end

    describe 'description' do
      let(:resource) { create :resource, description: '<p>foo</p>', is_video: false }
      before { get :show, params: { id: resource.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result['resource']['html']).to include(
        "<p>foo</p>"
      )}
    end
  end
end
