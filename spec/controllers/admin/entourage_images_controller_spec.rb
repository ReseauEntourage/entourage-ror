require 'rails_helper'
include AuthHelper

describe Admin::EntourageImagesController do
  let!(:user) { super_admin_basic_login }

  describe 'GET #index' do
    context 'has entourage_images' do
      let!(:entourage_image_list) { FactoryBot.create_list(:entourage_image, 2) }
      before { get :index }

      it { expect(assigns(:entourage_images)).to match_array(entourage_image_list) }
    end

    context 'has no entourage_images' do
      before { get :index }
      it { expect(assigns(:entourage_images)).to eq([]) }
    end
  end

  describe 'GET #new' do
    before { get :new }
    it { expect(assigns(:entourage_image)).to be_a_new(EntourageImage) }
  end

  describe 'POST #create' do
    context 'create success' do
      let(:entourage_image) { post :create, params: { 'entourage_image' => {
        title: 'Café solidaire'
      } } }
      it { expect { entourage_image }.to change { EntourageImage.count }.by(1) }
    end

    context 'create failure' do
      let(:entourage_image) { post :create, params: { 'entourage_image' => {
        title: nil
      } } }
        it { expect { entourage_image }.to change { EntourageImage.count }.by(0) }
    end
  end

  describe 'GET #edit' do
    let!(:entourage_image) { FactoryBot.create(:entourage_image) }
    before { get :edit, params: { id: entourage_image.to_param } }
    it { expect(assigns(:entourage_image)).to eq(entourage_image) }
  end

  describe 'PUT #update' do
    let!(:entourage_image) { FactoryBot.create(:entourage_image) }

    context 'common field' do
      before {
        put :update, params: { id: entourage_image.id, entourage_image: { title: 'Foo' } }
        entourage_image.reload
      }
      it { expect(entourage_image.title).to eq('Foo')}
    end
  end

  describe 'DELETE destroy' do
    let!(:entourage_image) { FactoryBot.create(:entourage_image) }
    before { delete :destroy, params: { id: entourage_image.id } }
    it { expect(EntourageImage.count).to eq(0) }
  end
end
