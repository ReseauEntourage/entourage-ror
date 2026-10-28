require 'rails_helper'
include AuthHelper

describe Admin::SensitiveWordsController do
  let!(:admin) { admin_basic_login }

  describe 'GET index' do
    let!(:word) { FactoryBot.create(:sensitive_word, raw: 'exemple', category: 'Insulte') }

    before { get :index }

    it { expect(response).to be_successful }
    it { expect(assigns(:words)).to include(word) }
  end

  describe 'GET index with search' do
    let!(:matching) { FactoryBot.create(:sensitive_word, raw: 'grenade') }
    let!(:other) { FactoryBot.create(:sensitive_word, raw: 'couteau') }

    before { get :index, params: { search: 'gren' } }

    it { expect(assigns(:words)).to include(matching) }
    it { expect(assigns(:words)).not_to include(other) }
  end

  describe 'POST create' do
    context 'with valid params' do
      before do
        post :create, params: { sensitive_word: { raw: 'nouveaumot', category: 'Insulte', match_type: 'exact', scope: 'all' } }
      end

      it { expect(response).to redirect_to(admin_sensitive_words_path) }
      it { expect(SensitiveWord.find_by(raw: 'nouveaumot')).to be_present }
      it { expect(SensitiveWord.find_by(raw: 'nouveaumot').created_by).to eq(admin) }
    end

    context 'with a duplicate word' do
      before do
        FactoryBot.create(:sensitive_word, raw: 'doublon')
        post :create, params: { sensitive_word: { raw: 'doublon', category: 'Insulte', match_type: 'exact', scope: 'all' } }
      end

      it { expect(response).to render_template(:new) }
      it { expect(SensitiveWord.where(raw: 'doublon').count).to eq(1) }
    end
  end

  describe 'PATCH update' do
    let!(:word) { FactoryBot.create(:sensitive_word, raw: 'ancien', category: 'Insulte') }

    before { patch :update, params: { id: word.id, sensitive_word: { category: 'Violence / Sexualité / Famille' } } }

    it { expect(response).to redirect_to(admin_sensitive_words_path) }
    it { expect(word.reload.category).to eq('Violence / Sexualité / Famille') }
  end

  describe 'DELETE destroy' do
    let!(:word) { FactoryBot.create(:sensitive_word, raw: 'a_supprimer') }

    before { delete :destroy, params: { id: word.id } }

    it { expect(response).to redirect_to(admin_sensitive_words_path) }
    it { expect(SensitiveWord.find_by(id: word.id)).to be_nil }
  end

  describe 'rendering (regression: missing partial / template errors)' do
    render_views

    let!(:word) { FactoryBot.create(:sensitive_word, raw: 'exemple', category: 'Insulte') }

    it 'renders index' do
      get :index
      expect(response).to be_successful
    end

    it 'renders new' do
      get :new
      expect(response).to be_successful
    end

    it 'renders edit' do
      get :edit, params: { id: word.id }
      expect(response).to be_successful
    end
  end
end
