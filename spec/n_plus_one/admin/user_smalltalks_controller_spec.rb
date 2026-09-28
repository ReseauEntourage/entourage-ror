require 'rails_helper'
include AuthHelper

describe Admin::UserSmalltalksController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  # un centre d'intérêt différent par demande : les requêtes sur tags ne sont pas mises en cache
  def interests_pool
    %w[activites animaux bien-etre cuisine culture jeux nature sport]
  end

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          @interest_index = ((@interest_index || -1) + 1) % interests_pool.size

          member = create :public_user, interest_list: [interests_pool[@interest_index]]
          create :address, user: member, city: "Ville #{member.id}"

          create :user_smalltalk,
            user: member.reload,
            smalltalk: create(:smalltalk, participants: [member]),
            matched_at: Time.current
        end
      end

      def perform_request
        get :index, params: { matched: true }
      end

      def returned_items_count
        assigns(:user_smalltalks).to_a.size
      end
    end
  end
end
