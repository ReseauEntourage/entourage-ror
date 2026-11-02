require 'rails_helper'
include AuthHelper

describe Admin::ActivityFeedController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  # chaque création récente a son propre auteur : un compte, une action, un événement, un groupe
  def populate(count)
    count.times do |index|
      create :public_user, first_name: "Membre #{index}"
      create :entourage, title: "Action #{SecureRandom.hex(4)}", user: create(:public_user)
      create :outing, title: "Événement #{SecureRandom.hex(4)}", user: create(:public_user)
      create :neighborhood, name: "Groupe #{SecureRandom.hex(4)}", user: create(:public_user)
    end
  end

  def perform_request
    get :index
  end

  def returned_items_count
    assigns(:items).size
  end

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries', pending: "N+1 sur l'auteur des actions, événements et groupes (record.user)"
  end
end
