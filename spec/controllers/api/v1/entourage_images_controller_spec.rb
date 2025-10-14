require 'rails_helper'

describe Api::V1::EntourageImagesController do
  let(:user) { FactoryBot.create(:public_user) }

  describe 'GET index' do
    let!(:entourage_image_list) { FactoryBot.create_list(:entourage_image, 2) }

    context 'not signed in' do
      before { get :index }
      it { expect(response.status).to eq(401) }
    end

    context 'signed in' do
      before { get :index, params: { token: user.token } }
      subject { JSON.parse(response.body) }

      it { expect(response.status).to eq(200) }
      it { expect(subject['entourage_images'].count).to eq(2) }
      it {
        expect(
          subject['entourage_images'].map do |entourage_image|
            entourage_image['id']
          end
        ).to match_array(entourage_image_list.map(&:id))
      }
    end
  end

  describe 'GET show' do
    let(:entourage_image) { FactoryBot.create(:entourage_image) }

    before { get :show, params: { token: user.token, id: entourage_image.id } }
    subject { JSON.parse(response.body) }

    it { expect(subject['entourage_image']['id']).to eq(entourage_image.id) }
  end
end
