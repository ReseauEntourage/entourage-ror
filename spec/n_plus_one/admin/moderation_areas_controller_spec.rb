require 'rails_helper'
include AuthHelper

describe Admin::ModerationAreasController, type: :controller do
  render_views

  # departement est unique : une valeur distincte par zone
  def next_departement
    @departement = (@departement || 10) + 1
    @departement.to_s
  end

  def populate(count)
    count.times do
      create :moderation_area,
        departement: next_departement,
        animator: create(:public_user),
        sourcing: create(:public_user),
        referent_benevole: create(:public_user)
    end
  end

  def perform_request
    get :index
  end

  def returned_items_count
    assigns(:moderation_areas).to_a.size
  end

  describe 'GET index' do
    context 'as admin (read-only columns)' do
      let!(:user) { admin_basic_login }

      it_behaves_like 'an endpoint without N+1 queries'
    end

    context 'as super admin (select forms per area)' do
      let!(:user) { super_admin_basic_login }

      it_behaves_like 'an endpoint without N+1 queries'
    end
  end
end
