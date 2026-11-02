require 'rails_helper'
include AuthHelper

describe Admin::SensitiveWordsController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  # chaque mot a son propre auteur et sa propre catégorie
  def populate(count)
    count.times do
      create :sensitive_word, category: "Catégorie #{SecureRandom.hex(4)}", created_by: create(:public_user, admin: true)
    end
  end

  def perform_request
    get :index
  end

  def returned_items_count
    assigns(:words).to_a.size
  end

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries', pending: "N+1 sur l'auteur de chaque mot (word.created_by)"
  end
end
